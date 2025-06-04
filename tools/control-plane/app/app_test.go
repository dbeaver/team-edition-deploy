package app

import "testing"

func Test_parseWSLMachineIPAddr(t *testing.T) {

	tests := []struct {
		name    string
		arg     string
		want    string
		wantErr bool
	}{
		{
			name: "parse valid WSL machine IP address",
			arg: `
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether 00:15:5d:5b:bd:52 brd ff:ff:ff:ff:ff:ff
    inet 172.31.142.32/20 brd 172.31.143.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::215:5dff:fe5b:bd52/64 scope link
       valid_lft forever preferred_lft forever`,
			want:    "172.31.142.32",
			wantErr: false,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := parseWSLMachineIPAddr(tt.arg)
			if (err != nil) != tt.wantErr {
				t.Errorf("parseWSLMachineIPAddr() error = %v, wantErr %v", err, tt.wantErr)
				return
			}
			if got != tt.want {
				t.Errorf("parseWSLMachineIPAddr() got = %v, want %v", got, tt.want)
			}
		})
	}
}
