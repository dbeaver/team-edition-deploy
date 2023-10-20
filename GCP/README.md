## Deploy a Dbeaver instance in GCP

### Import Dbeaver custom image on your GCP account

- Navigate to "Compute Engine" -> "Images"  
![Alt text](<image1.png>)

- Click on "[+] CREATE IMAGE"
- Give it a name (dbeaver-te/-ce/-ee-ubuntu/rhel-%version%)
- For the "Source" field select "Virtual disk (VMDK, VHD)"
- If you are prompted to enable Cloud Build tools and grant permissions, do it
- Copy the following URI in the "Cloud Storage file" field and click BROWSE
`dbeaver-te-server/dbeaver`

![Alt text](image2.png)


- Select the version you need
- **The other fields are not required**
- Click on "Create". You may have to wait up to 15 minutes while the Dbeaver server custom image imports to your account  

![Alt text](image3.png)


### Create a new GCP Compute Engine instance from the imported image

- Open the tab "Images" and click on the name of the image that you just imported, and click on the "[+] Create instance" button  

![Alt text](image4.png)

- Give your instance a name
- In the "Machine configuration" section, make sure to pick a "Machine type" with recommended memory and cpu (4 CPUs and 16GB RAM) to run Dbeaver server.  

![Alt text](image5.png)

- In the "Boot disk" section, click the "Change" button
- From the "Custom images" tab, select the image that you just imported in the previous steps (dbeaver-te/-ce/-ee-ubuntu/rhel-%version%) from the drop down menu. Select a disk size of at least 100GB. When you are done, click on "Select"

![Alt text](<image6.png>)

- In the "Firewall" section, make sure to check the "Allow HTTP traffic" and "Allow HTTPS traffic" boxes so that your Dbeaver server instance can be open from internet.
- Finally, click on the "Create" button. After a few minutes, your Dbeaver server instance should be up and running  

![Alt text](image7.png)

You can check that your instance is running correctly by copying and pasting the "External IP" address provided by GCP into your browser

## Deploy a Dbeaver instance in GCP with google CLI

- Navigate to "Compute Engine"

- Click on "Activate Cloud Shell"

![Alt text](image.png)

- If you are prompted to authorized, do it

- In the terminal that opens, you can just enter the following command   

`gcloud beta compute instances create dbeaver-te-server \`
`--zone=us-central1-a \`  
`--machine-type=e2-standard-4 \`  
`--tags=http-server,https-server \`  
`--image=https://www.googleapis.com/compute/v1/projects/dbeaver-public/global/images/dbeaver-te-server-ubuntu-23-2-0 \`  
`--create-disk=auto-delete=yes \`  
`--boot-disk-size=100GB --boot-disk-device-name=dbeaver-te-server`  


Where: 
- `zone` - Zone of the instances to create. You can choose this from [GCP zones](https://cloud.google.com/compute/docs/regions-zones)  
- `machine-type` - Specifies the machine type used for the instances. (4 CPUs and 16GB RAM resources recommended)  
- `tags` - These tags allow network firewall rules and routes to be applied to specified VM instances.  
- `image` - Specifies the boot image for the instances. You can choose anyone from our public image.  
- `create-disk=auto-delete=yes` - Creates and attaches persistent disks to the instances. This persistent disk will be automatically deleted when the instance is deleted.  
- `boot-disk-size` - The size of the boot disk, is 100GB recommended.  
- `boot-disk-device-name` - The name the guest operating system will see for the boot disk.  

Dbeaver TE GCP public image list:
- `https://www.googleapis.com/compute/v1/projects/dbeaver-public/global/images/dbeaver-te-server-ubuntu-23-2-0`
- `https://www.googleapis.com/compute/v1/projects/dbeaver-public/global/images/dbeaver-te-server-rhel-23-2-0`


You can change the parameters you need for deployment yourself. For detailed information on working with GoogleCloud CLI, you can read the [documentation](https://cloud.google.com/sdk/gcloud/reference/beta/compute/instances/create).
