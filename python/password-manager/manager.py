import hashlib

def encrypt_password(pwd):
    return hashlib.sha256(pwd.encode()).hexdigest()

if __name__ == '__main__':
    print('Master Password Login...')