## Question 2: Restaurant Bill Calculator
def calculate_restaurant_bill(meal_cost):

    ##  Validation 1:
    if int(meal_cost) <= 0:
        print("Meal cost must be greater than 0")
        return False
    else:
        service_charge = meal_cost * 0.10
        amount_after_service = meal_cost + service_charge
        tax = amount_after_service * 0.05
        tip_amount = amount_after_service * 0.05
        total = amount_after_service + tax + tip_amount
    ##  Print with 2 decimal places
        print(f"Meal Cost: {meal_cost:.2f}")
        print(f"Service Charge (10%): {service_charge:.2f}")
        print(f"Amount after Service: {amount_after_service:.2f}")
        print(f"Tax (5%): {tax:.2f}")
        print(f"Tip (5%): {tip_amount:.2f}")
        print(f"Total Bill: {total:.2f}")
        return round(total, 2)

##  Take input from user
print("Enter meal cost")
try:
    meal_cost = float(input("Input: "))
    print("Expected Output:")
    total = print("Return:", calculate_restaurant_bill(meal_cost))
#    print("Thank you, Visit Again!")
except ValueError:
    print("Error: Please enter numbers only")