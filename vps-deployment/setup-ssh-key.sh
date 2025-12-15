#!/bin/bash
# QueShield SSH Key Setup Script
# Run this on VPS: ssh root@145.223.19.208
# Then paste these commands:

mkdir -p ~/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDZDnsWkgYMTJL6Y/fjffJHpnS9ki8ZsE6uO7T4QqdRfRWMMJtaUnvwWccbF8AIqlCVSivv3QZFJmYGwSo7KSFS84YmbWnqKhw0i/5chwjmUQ/miG7kKgRmZeRozIKVfP2QJZOkuxJ/iGZacKLyL3Ayow1pXDIKyY6R6JDA/Hrd12rpbIYOG5yQeIhYkBfhmWhxTgDpwUs32NYQBjyoMSb3UF8KpzvdxEcdhWPA1ii6vHuzfu9XQlpqMEn26vn9D575Lc/At0W/6yLv0US0Fk2v71cCRcFiNGMQ9U9DLPP3bER5mSv1WcNap3Y8OJhsC6Cq5ArLWLmexRpQ8FqhB6saqvXHwtwRGCY+aqOoD9WKdFeqnTYzR/B2Ubf6OpNNdck+8CR7JLXdRJ4ewYFw/zTpwCCU17Egdfbg0Z2RpV+LwtfQjqCvdlbeRzx+klVBnMiOqFCXkSXruxXjVo8lEd+3EQNrVaXLzGVvFp8DvgOxxAdhaoZB2U27ryp2fXNDnQGkStkqsDAx6QPKwFHyVD8ETjUIE9v5i4LLEU7REjIeu5fFkk1xA2++4VotEoZzEUELggASy+/RjYIafUcI1R8L+eMIZ9AE+Y8fdOZPqR82A4LqL055OOY58JJc+na5HFL3ERsLRbE/AYLBl6KcuFLvQLdPdgALmFUvuN1fznhzrw== user@vipechan" >> ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

echo "✅ SSH key setup complete! You can now use key-based authentication."
echo "Test with: ssh root@145.223.19.208 (should not ask for password)"
