provider "aws" {
  region  = "ap-south-1"
  profile = "ns"
}


resource "aws_key_pair" "key" {
   key_name = "key2"
   public_key ="ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAz3orUbX1W4CGxRIz0RSFhSEcrKfD3pyNglCIU0jQuI61lPo8v+Cn54TZ8rNkFDd+e0UylR+8Pz1zojqIz3QlWotNDdPOGUi2LXxFIg8Dk1iAh5qxSo5ZAm0kS6LK5wA6CQKVYlf2dRx7uMVqLSNgoJln0d6zm3m4oous4t+p3rtkrcMxoBhQ4Tg4JvRN3EMICI6fU5TPgedirkhwSaYb/30gqJYAdJPZAJ2/H8ARjVnjeKU5fI+qBfkUgX/NJMEJmnu52h7rnh3NPKUHHtDAAT4zStg0tBTYnt8QVU2Urlb1nsllfUlolBsF36BOnoGgKAamLu0tfiTgpxj3Rl6ZpQ== rsa-key-20200613"
}

variable "key_name" {
 type= string
 default = "key2"
}

resource "aws_security_group" "sg" {
  name        = "sg"
  description = "Allow ssh and http for webhosting"
  vpc_id      = "vpc-98fee3f0"

  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


 egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg"
  }
}


resource "aws_instance" "myinst" {
    ami = "ami-0447a12f28fddb066" 
    instance_type = "t2.micro"
    availability_zone = "ap-south-1a"

user_data = <<-EOF
                #! /bin/bash
                sudo yum install httpd -y
                sudo systemctl start httpd
                sudo systemctl enable httpd
                sudo yum install git -y
                mkfs.ext4 /dev/xvdf1
                mount /dev/xvdf1 /var/www/html
                
                git clone https://github.com/naman09717/nsfile.git
                cd nsfile
                cp index.html /var/www/html
 EOF

    tags = {
        Name = "os1"   
    }
    key_name = var.key_name
    security_groups  = [ aws_security_group.sg.name ]
}


resource "aws_ebs_volume" "vol" {
  availability_zone = aws_instance.myinst.availability_zone
  size              = 1

  tags = {
    Name = "data-volume"
  }
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.vol.id
  instance_id = aws_instance.myinst.id
  force_detach = true
}


resource "aws_s3_bucket" "ns123456" {
  bucket = "ns123456"
  acl    = "public-read"

  tags = {
    Name        = "ns123456"
    Environment = "Dev"
  }
versioning{
 enabled = true
}
}

resource "aws_s3_bucket_object" "s3object" {
  bucket = aws_s3_bucket.ns123456.id
  key    = "3.jpg"
  source = "C:/Users/HP/Downloads/3.jpg"
}


resource "aws_cloudfront_distribution" "mycf" {
    origin {
        domain_name = "ns123456.s3.amazonaws.com"
        origin_id = "S3-ns123456" 


        custom_origin_config {
            http_port = 80
            https_port = 80
            origin_protocol_policy = "match-viewer"
            origin_ssl_protocols = ["TLSv1", "TLSv1.1", "TLSv1.2"] 
        }
    }
       
    enabled = true


    default_cache_behavior {
        allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
        cached_methods = ["GET", "HEAD"]
        target_origin_id = "S3-ns123456"


        
        forwarded_values {
            query_string = false
        
            cookies {
               forward = "none"
            }
        }
        viewer_protocol_policy = "allow-all"
        min_ttl = 0
        default_ttl = 3600
        max_ttl = 86400
    }
  
    restrictions {
        geo_restriction {
           
            restriction_type = "none"
        }
    }


 
    viewer_certificate {
        cloudfront_default_certificate = true
    }
}

