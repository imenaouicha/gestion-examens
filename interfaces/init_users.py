import bcrypt

def hash_pwd(pwd):
    return bcrypt.hashpw(pwd.encode(), bcrypt.gensalt()).decode()

users = {
    "etud1@univ.dz": "Etud@2025",
    "prof1@univ.dz": "Prof@2025",
    "admin.exam@univ.dz": "AdminExam@2025",
    "chef.info@univ.dz": "ChefInfo@2025",
   
    "doyen@univ.dz": "Doyen@2025"
}

for email, pwd in users.items():
    print(email, "=>", hash_pwd(pwd))

