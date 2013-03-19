# Loan Calculator

## Using the calculator

Currently deployed at http://aiddata-loan-calculator.herokuapp.com.


### Making a request
GET or POST  data to `/calculate` to find the grant element of a loan, for example: http://aiddata-loan-calculator.herokuapp.com/calculate?value=1000&interest_rate=0.025&discount_rate=0.1&maturity=10&grace_period=2.5


Your request __must__ include:

- value 
- maturity (in years)

Your request __may__ include:

- grace_period (in years, defaults to 0)
- interest_rate (provide as a decimal, eg `0.05` for 5%, or defaults to 5% )
- discount_rate (provide as a decimal, eg `0.1` for 10%, or defaults to 10%)
- year (for providing default discount rates or interest rates _not implemented_)
- repayments_per_year (defaults to 2, ie, semi-annual)
- disbursement_span_in_years (defaults to 1, ie, lump sum)
- disbursements_per_year (defaults to 1, ie, lump sum)


- include_lifecycle (pass "true" to see the calculated repayment steps )

### The Response
The JSON response includes the grant element value and grant element percent, as well as all values used in calculating the grant element.

If you request the loan lifecycle, it is also returned.


## Grant Element

Grant element (value) = (Present value of future disbursements) - (Present value of future repayments)
Grant element (percent) = Grant element value / (Present value of future disbursements)

__Face value__ of the loan = declared amount
__Present value__ of the loan = Present value of future disbursements

### Present value of future disbursements

You have to know how the loan is disbursed:

- Lump sum, all at once?
- Equal payments of frequency _x_ over _y_ years?

#### Lump sum
Present value of future disbursement = Face value

#### Equal payments of frequency _x_ over _y_ years

### Present value of future repayments

You have to know how the loan is repaid:

- When:
    - Grace period of _x_ years?
    - Maturity of _x_ years?

- How:
    - Lump sum, all at once
    - Equal Principal Payments

- Discount Rate: 
#### Equal Principal Payments

This means you pay off an equal share of the original amount plus accrued interest for that period.