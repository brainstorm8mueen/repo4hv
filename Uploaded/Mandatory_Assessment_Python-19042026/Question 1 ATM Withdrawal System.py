## Question 1: ATM Withdrawal System
def atm_withdrawal(withdrawal_amount):
    current_balance = 5000
    errors = []

    ## Validation 1
    if withdrawal_amount <= 0:
        errors.append("Withdrawal amount must be greater than 0")

    ## Validation 2
    if withdrawal_amount % 500 != 0:
        errors.append("Withdrawal amount must be multiple of 500")

    ## Validation 3
    if withdrawal_amount > current_balance:
        errors.append(f"Insufficient balance. Available: {current_balance}")
    if errors:
        print("Error:")
        for error in errors:
            print(error)
        return False
    remaining_balance = current_balance - withdrawal_amount
    print(f"Withdrawal successful. Amount: {withdrawal_amount}")
    print(f"Remaining balance: {remaining_balance}")
    return True
## Take input from user
print("Enter withdrawal amount")
try:
    amount = int(input("Input: "))
    print("Expected Output:")
    print("Return:", atm_withdrawal(amount))
#   import getpass
#   pin = int(getpass.getpass("Enter ATM PIN: "))
#   if pin == 5841:
#       print("PIN accepted")
##  Call the function
#       print("Return:", atm_withdrawal(amount))
except ValueError:
    print("Error: Please enter numbers only")