#this block to find lates_AMI (OS) "Amazon linux" filtered by name; step1 #optional for dynamic search

data "aws_ami" "app-ai" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
   }
}

#this block to create EC2 "webAPP" resource_by help from step1 & step2 

resource "aws_instance" "web1" {
  ami           = data.aws_ami.app-ai.id
  instance_type = var.HW_specifications
  #PUT YOUR OWN KEY
  key_name 		= var.write_yourkeyname
  tags = {
    Name = "web-app"
  }
  vpc_security_group_ids = ["${aws_security_group.allow_https_ssh.id}"]
  
 /* you created before in the selected region (.pem or .ppk),dont put contect here as it's sensetive data, so instead 
      put xyz.pem as a file in terraform folder which you run this code from or create new private key using
      aws_key_pair block, refering to https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair */

  #optional : count= var.need_HA==true?2:1 >if you need HA will create 2 EC2, otherwise 1, dont forget vaiable details
  ##############################################################
  # Establishes connection to be used by all, generic remote provisioners (i.e. file/remote-exec)
 
  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key =  file ( var.write_dot_slash_yourkeyname_dot_pem ) 
    host     = self.public_ip
   }

  provisioner "remote-exec" {
    inline = [ 
      "sudo yum update -y",
      "sudo amazon-linux-extras install -y nginx1",
      "sudo systemctl enable nginx",
      "sudo systemctl start nginx",
    ]
  }
}
  
  #create eip
  resource "aws_eip" "pip" {
  vpc      = true
}

#associate eip to instance created

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.web1.id 
  allocation_id = aws_eip.pip.id
}

#what's you eip?

output "eip_eip" {
  value = aws_eip.pip.public_ip
  
}

#Dynamic security Group

resource "aws_security_group" "allow_https_ssh" {
  name        = "allow_for_nginx"
 egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    #cidr_blocks = ["${aws_eip.pip.public_ip}/32"] >> For security restrictions only
  }
 dynamic "ingress" {
    for_each = var.opened_ports
    content{
     description      = "Conn from VPC"
     from_port        = ingress.value
     to_port          = ingress.value
     protocol         = "tcp"
     cidr_blocks      = ["0.0.0.0/0"]
     
  
    }

  
  }

}

####################################################################
#variables section# + terraform.tfvars in another separated section
#####################################################################

# this block is just variable for HW_specification; step2 #optional for dynamic selection
 variable "HW_specifications"{}

#must your key file in same terra folder:A,B
#A:For Key_Pair (enter your own key pair name ex: key1 )
variable "write_yourkeyname" {}

# B:For Key_Pair for config managet purpose (enter your own key pair name ex: ./key1.pem )
variable "write_dot_slash_yourkeyname_dot_pem" {} 

# this to choose region:
variable "Select_region-ex_us-east-1" {}

# For SG
variable "opened_ports" {}

#################################### [Thank You: Sameh Palas] ############################