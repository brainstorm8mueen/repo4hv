## Question 3: Login Authentication System
def validate_login(username, password):

    ##  Validation 1: Username length
    if len(username) < 5:
        print("Username must be at least 5 characters")
        return False
    
    ##  Validation 2: Password length
    if len(password) < 8:
        print("Password must be at least 8 characters")
        return False
    
    ##  Validation 3: Password must contain at least one digit
    has_digit = False
    for char in password:
        if char.isdigit():
            has_digit = True
            break
    if not has_digit:
        print("Password must contain at least one digit")
        return False
    
    ##  If all validations pass
    print("")
    print("Expected Output:")
    print("Login successful")
    return True
##  Take input from user
print("Input:")
username = input("username: ")
password = input("password: ")
#import getpass
#password = getpass.getpass("Enter password: ")
##  Call function and print return value
result = validate_login(username, password)
print("Return:", result)