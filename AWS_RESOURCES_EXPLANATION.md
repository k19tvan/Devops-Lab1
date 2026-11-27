# BÁO CÁO CHI TIẾT: Ý NGHĨA VÀ CHỨC NĂNG CÁC TÀI NGUYÊN AWS TRONG BÀI LAB 01
## DỰ ÁN: NT548 LAB 01 - AWS INFRASTRUCTURE AS CODE

---

## MỤC LỤC
1. [BẢNG TRA CỨU NHANH TẤT CẢ TÀI NGUYÊN AWS](#1-bảng-tra-cứu-nhanh-tất-cả-tài-nguyên-aws)
2. [CHI TIẾT TỪNG TÀI NGUYÊN AWS VÀ VAI TRÒ CỦA NÓ](#2-chi-tiết-từng-tài-nguyên-aws-và-vai-trò-của-nó)
   - 2.1. Nhóm Mạng Cơ Bản (Networking Foundation)
     - Virtual Private Cloud (VPC)
     - Public Subnet & Private Subnet
     - Internet Gateway (IGW) & Gateway Attachment
   - 2.2. Nhóm Dịch Chuyển Địa Chỉ Mạng (NAT Services)
     - Elastic IP (EIP)
     - NAT Gateway
   - 2.3. Nhóm Điều Hướng Mạng (Routing & Traffic Control)
     - Route Tables (Public & Private)
     - Routes (Định tuyến 0.0.0.0/0)
     - Route Table Associations
   - 2.4. Nhóm Tường Lửa & An Ninh Mạng (Firewall & Security)
     - Default Security Group (và cơ chế khóa chặt Lockdown)
     - Public Security Group (Bastion Firewall)
     - Private Security Group (Internal Firewall)
     - Ingress & Egress Rules (SG Chaining)
   - 2.5. Nhóm Điện Toán & Lưu Trữ (Compute, OS & Storage)
     - Amazon Machine Image (AMI AL2023)
     - Elastic Block Store (EBS gp3 Encrypted)
     - Instance Metadata Service v2 (IMDSv2)
     - Public EC2 Instance (Bastion Host)
     - Private EC2 Instance (Internal Server)
     - Key Pair (Khóa SSH)
   - 2.6. Nhóm Tự Động Hóa Đặc Biệt (CloudFormation Lambda Automation)
     - IAM Execution Role
     - Lambda Function & Custom Resource
3. [CHỨC NĂNG CÁC TÀI NGUYÊN TRONG 3 LUỒNG HOẠT ĐỘNG THỰC TẾ](#3-chức-năng-các-tài-nguyên-trong-3-luồng-hoạt-động-thực-tế)
   - 3.1. Luồng 1: Quản trị viên SSH từ Internet vào máy Public EC2
   - 3.2. Luồng 2: Quản trị viên SSH nhảy cóc vào máy Private EC2 (ProxyCommand)
   - 3.3. Luồng 3: Máy Private EC2 tải gói phần mềm từ Internet và nhận phản hồi
4. [BẢNG ĐỐI CHIẾU TERRAFORM VÀ CLOUDFORMATION](#4-bảng-đối-chiếu-terraform-và-cloudformation)

---

## 1. BẢNG TRA CỨU NHANH TẤT CẢ TÀI NGUYÊN AWS

| Tên Tài Nguyên AWS | Kiểu Resource trong Terraform | Kiểu Resource trong CloudFormation | Phân Loại |
| :--- | :--- | :--- | :--- |
| **VPC** | `aws_vpc` | `AWS::EC2::VPC` | Mạng cốt lõi |
| **Public Subnet** | `aws_subnet.public` | `AWS::EC2::Subnet` | Mạng cốt lõi |
| **Private Subnet** | `aws_subnet.private` | `AWS::EC2::Subnet` | Mạng cốt lõi |
| **Internet Gateway** | `aws_internet_gateway` | `AWS::EC2::InternetGateway` | Cổng ngoại vi |
| **Gateway Attachment**| Tự động trong `aws_internet_gateway` | `AWS::EC2::VPCGatewayAttachment` | Liên kết cổng |
| **Elastic IP** | `aws_eip` | `AWS::EC2::EIP` | Địa chỉ mạng |
| **NAT Gateway** | `aws_nat_gateway` | `AWS::EC2::NatGateway` | Dịch địa chỉ |
| **Route Table (Public/Private)**| `aws_route_table` | `AWS::EC2::RouteTable` | Bảng định tuyến |
| **Route (Public/Private)** | `aws_route` | `AWS::EC2::Route` | Quy tắc chỉ đường |
| **Subnet Association** | `aws_route_table_association` | `AWS::EC2::SubnetRouteTableAssociation` | Gắn bảng định tuyến |
| **Default Security Group** | `aws_default_security_group` | Xử lý bằng Lambda Custom Resource | Tường lửa mặc định |
| **Public Security Group** | `aws_security_group.public` | `AWS::EC2::SecurityGroup` | Tường lửa máy Bastion |
| **Private Security Group**| `aws_security_group.private`| `AWS::EC2::SecurityGroup` | Tường lửa máy nội bộ |
| **Ingress/Egress Rules** | `aws_vpc_security_group_*_rule` | Thuộc tính `SecurityGroupIngress/Egress`| Quy tắc tường lửa |
| **AMI OS Image** | `data "aws_ami"` | `AWS::SSM::Parameter::Value` | Ảnh hệ điều hành |
| **Launch Template** | Tích hợp trong `aws_instance` | `AWS::EC2::LaunchTemplate` | Bản mẫu máy chủ |
| **Public EC2** | `aws_instance.public` | `AWS::EC2::Instance` | Máy ảo tính toán |
| **Private EC2** | `aws_instance.private` | `AWS::EC2::Instance` | Máy ảo tính toán |
| **Key Pair** | Tham chiếu biến `var.key_name` | Tham chiếu parameter `KeyName` | Xác thực SSH |
| **Lambda & IAM Role** | Không cần (dùng resource native) | `AWS::IAM::Role` + `AWS::Lambda::Function` | Tự động hóa stack |

---

## 2. CHI TIẾT TỪNG TÀI NGUYÊN AWS VÀ VAI TRÒ CỦA NÓ

### 2.1. Nhóm Mạng Cơ Bản (Networking Foundation)

#### 1. AWS VPC (Virtual Private Cloud)
- **Khái niệm**: Là một trung tâm dữ liệu ảo độc lập dành riêng cho tài khoản AWS của bạn, được cô lập logic hoàn toàn với các mạng ảo khác trên đám mây AWS.
- **Cấu hình trong lab**: Dải mạng `10.0.0.0/16` (cung cấp 65.536 địa chỉ IP nội bộ), bật phân giải tên miền DNS (`enable_dns_support` và `enable_dns_hostnames`).
- **Chức năng trong luồng hoạt động**: Tạo ra một hàng rào bao bọc toàn bộ máy chủ, cổng mạng và bảng định tuyến của bài lab, giúp các thành phần nội bộ có thể giao tiếp với nhau bằng dải IP riêng biệt `10.0.x.x`.
- **Nếu thiếu nó**: Không thể triển khai bất kỳ máy chủ hay dịch vụ mạng nào vì không có không gian địa chỉ mạng.

#### 2. Public Subnet
- **Khái niệm**: Một phân đoạn mạng con nằm bên trong VPC, được cấu hình để các gói tin có thể đi thẳng ra ngoài Internet và ngược lại.
- **Cấu hình trong lab**: Dải IP `10.0.1.0/24` (tối đa 251 IP khả dụng sau khi trừ 5 IP nội bộ của AWS), đặt tại vùng khả dụng `us-east-1a`, bật cờ `map_public_ip_on_launch = true`.
- **Chức năng trong luồng hoạt động**: Làm "vùng đệm an toàn" tiếp xúc với Internet, là nơi đóng quân của máy chủ Bastion Host và thiết bị NAT Gateway.
- **Nếu thiếu nó**: Toàn bộ hệ thống sẽ trở thành mạng nội bộ cô lập 100%, quản trị viên không thể SSH từ xa vào để làm việc.

#### 3. Private Subnet
- **Khái niệm**: Một phân đoạn mạng con biệt lập bên trong VPC, tuyệt đối không có đường đi trực tiếp ra Internet và không tiếp nhận kết nối chủ động từ ngoài vào.
- **Cấu hình trong lab**: Dải IP `10.0.2.0/24`, đặt cùng vùng khả dụng `us-east-1a`, tắt cờ cấp Public IP (`map_public_ip_on_launch = false`).
- **Chức năng trong luồng hoạt động**: Chứa máy chủ Private EC2 (đóng vai trò như máy chủ cơ sở dữ liệu hoặc xử lý backend nghiệp vụ quan trọng). Bảo vệ máy chủ này khỏi các đợt rà quét cổng, tấn công DDoS từ mạng công cộng.
- **Nếu thiếu nó**: Các máy chủ backend buộc phải nằm ở Public Subnet, đối mặt với nguy cơ bị tấn công mạng trực tiếp từ Internet.

#### 4. Internet Gateway (IGW) & Gateway Attachment
- **Khái niệm**: Một thành phần mạng phần mềm có tính sẵn sàng cao, co giãn tự động của AWS, đóng vai trò làm cửa ngõ duy nhất kết nối giữa VPC và mạng Internet toàn cầu.
- **Cấu hình trong lab**: Tạo 1 Internet Gateway mang tên `nt548-lab01-igw` và gắn (attach) trực tiếp vào VPC.
- **Chức năng trong luồng hoạt động**:
  - Dịch chuyển địa chỉ mạng 1:1 cho các máy có Public IP (Public NAT).
  - Cho phép gói tin SSH từ IP của quản trị viên đi xuyên vào VPC để tới máy Bastion.
  - Cho phép các gói tin từ NAT Gateway đi ra ngoài Internet.
- **Nếu thiếu nó**: VPC hoàn toàn mất kết nối với mạng Internet bên ngoài.

---

### 2.2. Nhóm Dịch Chuyển Địa Chỉ Mạng (NAT Services)

#### 5. Elastic IP (EIP)
- **Khái niệm**: Một địa chỉ IPv4 công cộng tĩnh, cố định và thuộc quyền sở hữu riêng của bạn trên AWS, không bị thay đổi khi tài nguyên khởi động lại.
- **Cấu hình trong lab**: Cấp phát 1 địa chỉ EIP với phạm vi `domain = "vpc"`.
- **Chức năng trong luồng hoạt động**: Gán trực tiếp vào cổng mạng của NAT Gateway. Toàn bộ máy chủ trong Private Subnet khi ra ngoài Internet sẽ dùng chung địa chỉ IP tĩnh đại diện này.
- **Nếu thiếu nó**: Không thể khởi tạo được NAT Gateway (AWS bắt buộc NAT Gateway loại Public phải gắn kèm một Elastic IP).

#### 6. NAT Gateway (Network Address Translation)
- **Khái niệm**: Dịch vụ quản lý được tối ưu hóa cao của AWS, làm nhiệm vụ dịch địa chỉ IP nguồn (Source NAT). Cho phép các máy chủ trong mạng riêng truy cập ra ngoài nhưng ngăn chặn chiều ngược lại.
- **Cấu hình trong lab**: Đặt tại **Public Subnet**, gắn với Elastic IP ở trên, loại kết nối `connectivity_type = "public"`.
- **Chức năng trong luồng hoạt động**:
  - Khi máy `Private EC2` muốn chạy lệnh `yum update` hoặc `dnf install`: Gói tin được gửi đến NAT Gateway.
  - NAT Gateway tráo đổi địa chỉ IP nguồn (`10.0.2.x`) thành địa chỉ Elastic IP công cộng rồi gửi ra Internet Gateway.
  - Khi máy chủ Internet trả lời về, NAT Gateway chuyển tiếp gói tin đó về đúng máy Private EC2.
- **Nếu thiếu nó**: Máy chủ `Private EC2` sẽ không thể cập nhật phần mềm, tải thư viện hay kết nối với các API bên ngoài.

---

### 2.3. Nhóm Điều Hướng Mạng (Routing & Traffic Control)

#### 7. Route Tables (Bảng Định Tuyến)
- **Khái niệm**: Tập hợp các quy tắc (Routes) xác định đường đi cho các gói tin mạng xuất phát từ các Subnet bên trong VPC.
- **Cấu hình trong lab**: Tạo 2 bảng riêng biệt:
  - `Public Route Table`: Dành riêng cho Public Subnet.
  - `Private Route Table`: Dành riêng cho Private Subnet.
- **Chức năng trong luồng hoạt động**: Tách đôi bản đồ định hướng của mạng. Đảm bảo máy ở Public Subnet đi một đường, máy ở Private Subnet đi một đường khác biệt hoàn toàn.

#### 8. Routes (Các Tuyến Đường Cụ Thể)
- **Khái niệm**: Quy tắc chỉ đường chi tiết dạng: "Nếu gói tin muốn đến đích X, hãy gửi nó qua cổng Y".
- **Cấu hình trong lab**:
  - `Public Internet Route`: Đích đến `0.0.0.0/0` (tất cả IP ngoài VPC) $\rightarrow$ Gửi tới **Internet Gateway**.
  - `Private Internet Route`: Đích đến `0.0.0.0/0` $\rightarrow$ Gửi tới **NAT Gateway**.
- **Chức năng trong luồng hoạt động**: Là biển chỉ dẫn thực tế. Nếu không có các dòng này, gói tin đi ra ngoài mạng nội bộ sẽ bị drop (hủy bỏ) ngay tại chỗ.

#### 9. Subnet Route Table Association (Liên Kết Bảng Định Tuyến)
- **Khái niệm**: Cầu nối logic để áp đặt một Bảng định tuyến cụ thể lên một Phân mạng (Subnet).
- **Cấu hình trong lab**:
  - Gắn Public Subnet vào Public Route Table.
  - Gắn Private Subnet vào Private Route Table.
- **Chức năng trong luồng hoạt động**: Xác định subnet nào chịu sự điều phối của bảng định tuyến nào.
- **Nếu thiếu nó**: Subnet sẽ tự động rơi về Bảng định tuyến mặc định (Main Route Table) của VPC, làm hỏng kiến trúc bảo mật phân tầng.

---

### 2.4. Nhóm Tường Lửa & An Ninh Mạng (Firewall & Security)

#### 10. Default Security Group (và kỹ thuật Lockdown)
- **Khái niệm**: Nhóm an ninh mặc định do AWS tự động sinh ra khi tạo VPC.
- **Cấu hình trong lab**: Xóa sạch toàn bộ quy tắc Ingress (chiều vào) và Egress (chiều ra), biến nó thành một nhóm tường lửa câm hoàn toàn.
- **Chức năng trong luồng hoạt động**: Ngăn chặn rủi ro bảo mật (theo tiêu chuẩn CIS Benchmark). Nếu ai đó vô tình tạo tài nguyên mà quên chọn Security Group, tài nguyên đó bị rơi vào nhóm này và sẽ bị cô lập hoàn toàn, không thể lây nhiễm hay bị khai thác.

#### 11. Public Security Group (Tường lửa máy Bastion)
- **Khái niệm**: Tường lửa ảo kiểm soát lưu lượng mạng ở cấp độ máy chủ ảo (Network Card) cho máy Public EC2.
- **Cấu hình trong lab**:
  - Inbound: Chỉ mở duy nhất cổng TCP 22 (SSH) từ địa chỉ IP của quản trị viên (`allowed_ssh_cidr`).
  - Outbound: Mở toàn bộ (`0.0.0.0/0`, all protocols) để máy có thể truy cập Internet.
- **Chức năng trong luồng hoạt động**: Lá chắn ngăn chặn mọi kẻ xâm nhập trên Internet, chỉ cho phép duy nhất một địa chỉ IP tin cậy của bạn được phép gõ cửa port 22.

#### 12. Private Security Group (Tường lửa máy nội bộ)
- **Khái niệm**: Tường lửa ảo bảo vệ cho máy Private EC2.
- **Cấu hình trong lab**:
  - Inbound: Mở cổng TCP 22 nhưng nguồn không phải là IP mà là `referenced_security_group_id = Public Security Group` (Security Group Chaining).
  - Outbound: Mở toàn bộ (`0.0.0.0/0`) để gửi request tải cập nhật qua NAT Gateway.
- **Chức năng trong luồng hoạt động**: Đảm bảo máy Private EC2 chỉ nói chuyện SSH với máy Bastion Host, loại bỏ hoàn toàn khả năng bị truy cập trái phép từ bất kỳ nguồn nào khác.

---

### 2.5. Nhóm Điện Toán & Lưu Trữ (Compute, OS & Storage)

#### 13. Amazon Machine Image (AMI) - Amazon Linux 2023
- **Khái niệm**: Bản đóng gói hệ điều hành đã được AWS kiểm định, sẵn sàng để khởi động máy ảo.
- **Cấu hình trong lab**: Bản kiến trúc `x86_64`, thế hệ mới nhất AL2023 (`al2023-ami-kernel-default-x86_64`), tìm kiếm động qua Data Source hoặc SSM Parameter.
- **Chức năng trong luồng hoạt động**: Cung cấp nhân hệ điều hành Linux hiện đại, tối ưu cho môi trường đám mây AWS, hỗ trợ dnf package manager và các công cụ dòng lệnh cơ bản.

#### 14. Elastic Block Store (EBS) - gp3 Encrypted
- **Khái niệm**: Ổ cứng mạng gắn trực tiếp vào máy chủ EC2 (tương tự ổ SSD gắn trong máy tính thật).
- **Cấu hình trong lab**: Dung lượng 8 GiB, loại ổ thế hệ mới `gp3`, bật mã hóa `encrypted = true`, tự xóa khi hủy máy `delete_on_termination = true`.
- **Chức năng trong luồng hoạt động**: Lưu trữ hệ điều hành, cấu hình SSH và dữ liệu người dùng. Cơ chế mã hóa bảo vệ dữ liệu ở trạng thái nghỉ, ngay cả khi ổ cứng bị chụp snapshot trái phép.

#### 15. Instance Metadata Service v2 (IMDSv2)
- **Khái niệm**: Cơ chế cung cấp thông tin cấu hình máy chủ thông qua địa chỉ IP nội bộ `169.254.169.254`.
- **Cấu hình trong lab**: Bắt buộc dùng `http_tokens = "required"`.
- **Chức năng trong luồng hoạt động**: Chống lại lỗ hổng bảo mật SSRF (Server-Side Request Forgery). Kẻ tấn công không thể đọc lén thông tin IAM credentials hoặc token của máy chủ qua các request HTTP đơn giản.

#### 16. Public EC2 Instance (Bastion Host / Jump Server)
- **Khái niệm**: Máy chủ ảo đóng vai trò trạm gác cổng trung gian.
- **Cấu hình trong lab**: Loại máy `t3.micro`, đặt tại Public Subnet, có gắn Public IP, đĩa root 8 GiB gp3, dùng key pair `nt548-lab01-key`.
- **Chức năng trong luồng hoạt động**: Làm "bàn đạp" (Jump Host). Bạn SSH vào máy này trước, sau đó từ máy này mở tiếp một phiên SSH thứ hai để vào máy nội bộ.

#### 17. Private EC2 Instance (Internal Server)
- **Khái niệm**: Máy chủ ảo nội bộ thực sự làm nhiệm vụ lưu trữ hoặc xử lý dữ liệu.
- **Cấu hình trong lab**: Loại máy `t3.micro`, đặt tại Private Subnet, không có Public IP, đĩa root 8 GiB gp3.
- **Chức năng trong luồng hoạt động**: Mô phỏng một máy chủ ứng dụng doanh nghiệp chuẩn mực được giấu kín sau lớp mạng bảo vệ.

#### 18. EC2 Key Pair (`nt548-lab01-key`)
- **Khái niệm**: Cặp khóa mã hóa bất đối xứng (Public Key lưu trên AWS, Private Key `.pem` lưu trên máy tính của bạn).
- **Chức năng trong luồng hoạt động**: Dùng để xác thực danh tính người dùng khi kết nối SSH vào các máy chủ Linux mà không cần dùng mật khẩu văn bản (tránh bị brute-force password).

---

### 2.6. Nhóm Tự Động Hóa Đặc Biệt (CloudFormation Lambda Automation)

#### 19. DefaultSecurityGroupRole (IAM Role)
- **Khái niệm**: Vai trò ủy quyền cho phép hàm Lambda thực thi các quyền hạn định trước.
- **Cấu hình trong lab**: Cấp quyền `ec2:DescribeSecurityGroups`, `ec2:RevokeSecurityGroupIngress`, `ec2:RevokeSecurityGroupEgress`, `ec2:CreateTags` trên tài khoản AWS.
- **Chức năng trong luồng hoạt động**: Cấp thẻ bài cho hàm Lambda thực hiện thao tác xóa rule trên Default Security Group một cách hợp lệ.

#### 20. DefaultSecurityGroupFunction & Custom Resource
- **Khái niệm**: Hàm serverless Python 3.12 được CloudFormation gọi tự động trong quá trình xây dựng stack.
- **Chức năng trong luồng hoạt động**: Bổ khuyết cho nhược điểm của CloudFormation (vốn không có resource native để quản lý Default SG như Terraform). Nó tự động xóa toàn bộ Ingress/Egress của Default SG và thông báo trạng thái `SUCCESS` về cho CloudFormation.

---

## 3. CHỨC NĂNG CÁC TÀI NGUYÊN TRONG 3 LUỒNG HOẠT ĐỘNG THỰC TẾ

### 3.1. Luồng 1: Quản trị viên SSH từ Internet vào máy Public EC2

```
[Máy cá nhân của Bạn] 
       │ 
       ▼ (1) Gửi gói tin TCP SYN tới Cổng 22 của Public IP
[Internet Gateway] 
       │ 
       ▼ (2) Dịch đích đến thành Private IP 10.0.1.x của Public Subnet
[Public Route Table] 
       │ 
       ▼ (3) Dẫn gói tin tới Card mạng của máy Bastion
[Public Security Group] 
       │ 
       ▼ (4) KIỂM TRA TƯỜNG LỬA: IP nguồn có khớp với allowed_ssh_cidr không?
       │     - KHÔNG: Drop ngay lập tức.
       │     - ĐÚNG: Cho phép đi qua.
[Public EC2 (Bastion)] 
       │ 
       ▼ (5) Kiểm tra Key Pair nt548-lab01-key -> Đăng nhập thành công!
```

---

### 3.2. Luồng 2: Quản trị viên SSH nhảy cóc vào máy Private EC2 (ProxyCommand)

Lệnh thực thi:
```powershell
ssh -i nt548-lab01-key.pem -o "ProxyCommand=ssh -i nt548-lab01-key.pem -W %h:%p ec2-user@PUBLIC_IP" ec2-user@PRIVATE_IP
```

```
[Máy cá nhân của Bạn]
       │
       ▼ (1) Thiết lập hầm ngầm SSH tới Public EC2 (Bastion)
[Public EC2 (Bastion)]
       │
       ▼ (2) Nhận cờ -W %h:%p, đóng vai trò Proxy chuyển tiếp gói tin sang IP 10.0.2.x
[VPC Router nội bộ]
       │
       ▼ (3) Chuyển gói tin từ Public Subnet (10.0.1.x) sang Private Subnet (10.0.2.x)
[Private Security Group]
       │
       ▼ (4) KIỂM TRA TƯỜNG LỬA: Gói tin đến từ đâu?
       │     - Đến từ một máy mang Public Security Group? -> HỢP LỆ!
[Private EC2 (Internal Server)]
       │
       ▼ (5) Xác thực chìa khóa trực tiếp với máy tính của Bạn -> Đăng nhập thành công!
```
*(Ghi chú: Khóa Private Key không bao giờ bị lưu trên máy Bastion, an toàn 100%)*

---

### 3.3. Luồng 3: Máy Private EC2 tải gói phần mềm từ Internet và nhận phản hồi

Ví dụ: Bạn đang ở trong máy `Private EC2` và gõ lệnh: `sudo dnf update -y`

```
[Private EC2]
       │
       ▼ (1) Tạo gói tin tìm kho phần mềm (ví dụ: IP 52.x.x.x trên Internet)
[Private Security Group]
       │
       ▼ (2) Kiểm tra Egress Rule: Cho phép đi ra ngoài (0.0.0.0/0) -> Cho qua
[Private Route Table]
       │
       ▼ (3) Đọc quy tắc: Đích đến 0.0.0.0/0 -> Đẩy sang NAT Gateway
[NAT Gateway (ở Public Subnet)]
       │
       ▼ (4) Source NAT: Thay đổi IP nguồn 10.0.2.x thành Elastic IP công cộng
[Public Route Table & IGW]
       │
       ▼ (5) Đẩy gói tin ra ngoài thế giới Internet
[Internet Repositories]
       │
       ▼ (6) Phản hồi dữ liệu tải về địa chỉ Elastic IP
[Internet Gateway & NAT Gateway]
       │
       ▼ (7) NAT Gateway nhận phản hồi, tra bảng dịch trạng thái và trả về đúng Private EC2
[Private EC2]
       │
       ▼ (8) Gói phần mềm được cập nhật thành công!
```

---

## 4. BẢNG ĐỐI CHIẾU TERRAFORM VÀ CLOUDFORMATION

| Trách nhiệm kiến trúc | Cách làm trong Terraform | Cách làm trong CloudFormation |
| :--- | :--- | :--- |
| **Tạo VPC & Subnets** | Dùng `aws_vpc` và `aws_subnet` trong module `network` | Dùng `AWS::EC2::VPC` và `AWS::EC2::Subnet` |
| **Cấp IP tĩnh cho NAT**| Dùng `aws_eip` trong module `nat` | Dùng `AWS::EC2::EIP` kèm `DependsOn: GatewayAttachment` |
| **Xây dựng NAT Gateway**| Dùng `aws_nat_gateway` | Dùng `AWS::EC2::NatGateway` |
| **Định tuyến ra Internet**| `aws_route` với `gateway_id` và `nat_gateway_id` | `AWS::EC2::Route` với `GatewayId` và `NatGatewayId` |
| **Khóa Default SG** | `aws_default_security_group` xóa `ingress`/`egress` | Viết hàm Lambda Python chạy qua `Custom Resource` |
| **Cấu hình Security Group**| Tách riêng resource `aws_security_group` và các rule `aws_vpc_security_group_*_rule` | Gom chung trong resource `AWS::EC2::SecurityGroup` |
| **Cấu hình chuẩn hóa EC2**| Khai báo trực tiếp trong block `aws_instance` | Dùng `AWS::EC2::LaunchTemplate` dùng chung cho 2 máy |
| **Lấy AMI mới nhất** | Dùng `data "aws_ami"` quét tự động | Dùng kiểu dữ liệu `AWS::SSM::Parameter::Value` |
