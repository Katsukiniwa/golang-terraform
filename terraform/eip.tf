resource "aws_eip" "public_1a" {
  tags = {
    Name = "sample"
  }
}

resource "aws_eip" "public_1c" {
  tags = {
    Name = "sample"
  }
}
