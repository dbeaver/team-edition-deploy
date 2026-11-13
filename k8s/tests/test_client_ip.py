"""Offline Helm regression tests. Requires Helm and PyYAML."""

import copy
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

import yaml


class UniqueKeyLoader(yaml.SafeLoader):
    """Reject duplicate keys that ordinary YAML loading silently overwrites."""

    def construct_mapping(self, node, deep=False):
        keys = [self.construct_object(key, deep=deep) for key, _ in node.value]
        if len(keys) != len(set(keys)):
            raise ValueError("Duplicate YAML key")
        return super().construct_mapping(node, deep=deep)


class ClientIPTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = Path(__file__).resolve().parents[1] / "cbte"
        cls.values = yaml.safe_load((cls.source / "values.yaml.example").read_text())
        cls.values["backend"]["cloudbeaver_db_password"] = "render-test-only"

    def render(self, values):
        with tempfile.TemporaryDirectory() as directory:
            chart = Path(directory) / "chart"
            shutil.copytree(self.source, chart)
            # Dummy PEM envelopes satisfy render checks; no real keys are needed.
            for folder in ("crossSsl", "secretSsl", "ingressSsl"):
                (chart / folder).mkdir(exist_ok=True)
                for name in ("cert.crt", "fullchain.pem"):
                    (chart / folder / name).write_text(
                        "-----BEGIN CERTIFICATE-----\nTEST\n-----END CERTIFICATE-----\n"
                    )
                for name in ("key.key", "privkey.pem"):
                    (chart / folder / name).write_text(
                        "-----BEGIN PRIVATE KEY-----\nTEST\n-----END PRIVATE KEY-----\n"
                    )
            path = Path(directory) / "values.yaml"
            path.write_text(yaml.safe_dump(values))
            subprocess.run(
                ["helm", "lint", str(chart), "-f", str(path)],
                check=True, capture_output=True, text=True,
            )
            result = subprocess.run(
                ["helm", "template", "client-ip-test", str(chart), "-f", str(path)],
                check=True, capture_output=True, text=True,
            )
        return [item for item in yaml.load_all(result.stdout, Loader=UniqueKeyLoader) if item]

    def test_forward_proxy(self):
        for state in (None, True, False):
            with self.subTest(state=state):
                values = copy.deepcopy(self.values)
                values.pop("ingressAnnotations", None)
                if state is None:
                    values.pop("forwardProxy", None)
                else:
                    values["forwardProxy"] = state
                docs = self.render(values)
                app = next(d for d in docs if d["kind"] == "Deployment"
                           and d["metadata"]["name"] == "cloudbeaver-te")
                env = app["spec"]["template"]["spec"]["containers"][0]["env"]
                actual = [e["value"] for e in env
                          if e["name"] == "CLOUDBEAVER_APP_FORWARD_PROXY"]
                self.assertEqual(actual, [] if state is None else [str(state).lower()])
                for other in docs:
                    if other["kind"] == "Deployment" and other is not app:
                        for container in other["spec"]["template"]["spec"]["containers"]:
                            self.assertNotIn("CLOUDBEAVER_APP_FORWARD_PROXY",
                                             [e["name"] for e in container.get("env", [])])

    def test_ingress_annotations(self):
        for controller in ("nginx", "haproxy", "aws-alb"):
            for scheme in ("http", "https"):
                with self.subTest(controller=controller, scheme=scheme):
                    values = copy.deepcopy(self.values)
                    values.update(ingressController=controller, httpScheme=scheme)
                    if controller == "aws-alb":
                        values["certificateARN"] = "arn:aws:acm:render-test"
                    values.pop("ingressAnnotations", None)
                    defaults = [d for d in self.render(values) if d["kind"] == "Ingress"]
                    key = ("alb.ingress.kubernetes.io/scheme" if controller == "aws-alb"
                           else f"{'nginx.ingress.kubernetes.io' if controller == 'nginx' else 'haproxy-ingress.github.io'}/proxy-body-size")
                    values["ingressAnnotations"] = {key: "override", "example.com/client-ip": "test"}
                    rendered = [d for d in self.render(values) if d["kind"] == "Ingress"]
                    self.assertEqual(len(rendered), 2)
                    for before, after in zip(defaults, rendered):
                        expected = dict(before["metadata"]["annotations"])
                        expected.update(values["ingressAnnotations"])
                        self.assertEqual(after["metadata"]["annotations"], expected)
                        self.assertEqual(after["spec"], before["spec"])


if __name__ == "__main__":
    unittest.main()
