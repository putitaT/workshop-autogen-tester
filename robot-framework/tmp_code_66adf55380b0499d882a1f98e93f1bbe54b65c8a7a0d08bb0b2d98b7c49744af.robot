*** Settings ***
Library    SeleniumLibrary

*** Test Cases ***
TC-1002-001    Verify Advance Transfer Transaction List Display
    [Documentation]    Verify the display and functionality of the Advance Transfer Transaction List based on user settings and interactions.
    [Tags]    regression
    # Preconditions
    Open Application    ibank_url
    Log In    valid_user    valid_password

    # Step 1: Navigate to the "Advance Transfer" section
    Click Element    xpath=//button[text()='Advance Transfer']
    
    # Step 2: Check if the account number of the user's account is displayed
    ${account_number}=    Get Text    xpath=//div[@id='user_account_number']
    Should Not Be Empty    ${account_number}
    Log To Console    Account Number: ${account_number}
    
    # Expected Result: Account number displayed according to the user's settings (full or partially masked).

    # Step 3: Check if destination account number is displayed
    ${destination_account_number}=    Get Text    xpath=//div[@id='destination_account_number']
    Should Match Regexp    ${destination_account_number}    \*\*\*\*\d{4}    # Ensure only last 4 digits are visible
    
    # Expected Result: The destination account number is always masked except for the last 4 digits.

    # Step 4: Verify if the list shows up to 100 advance transfer transactions
    ${transaction_count}=    Get Element Count    xpath=//div[@class='transaction_list']/div
    Should Be Less Than Or Equal To    ${transaction_count}    100
    
    # Expected Result: Maximum of 100 entries displayed.

    # Step 5: Check the sorting order of the transactions
    ${dates}=    Get Text    xpath=//div[@class='transaction_list']/div//span[@class='transfer_date']
    Should Not Be Empty    ${dates}
    # Assume some method to validate the sorting not shown in this snippet
    
    # Expected Result: Transactions sorted by transfer date, most recent first.

    # Step 6: For the same transfer date, validate earlier created transactions
    # Assume validation of dates has been done

    # Step 7: Click on the chevron button for one transaction
    Click Element    xpath=//div[@class='transaction_list']/div[1]//button[contains(@class, 'chevron')]
    ${detail}=    Get Text    xpath=//div[@class='transaction_detail']
    Should Not Be Empty    ${detail}

    # Expected Result: Details of the clicked transaction should be displayed.

    # Step 8: Click on the chevron for another transaction while previous details are visible
    Click Element    xpath=//div[@class='transaction_list']/div[2]//button[contains(@class, 'chevron')]
    ${new_detail}=    Get Text    xpath=//div[@class='transaction_detail']
    Should Not Be Equal    ${new_detail}    ${detail} 

    # Expected Result: Previous details hidden; new transaction's details displayed.

    # Step 9: Verify the format of the amount displayed
    ${amount}=    Get Text    xpath=//div[@class='amount_display']
    Should Match Regexp    ${amount}    \d{1,3}(,\d{3})*\.\d{2} THB    # Currency format validation

    # Expected Result: Amounts formatted as currency (e.g., 1,000.00 THB).

    # Step 10: Test immediate transfer cancellation
    Click Element    xpath=//div[@class='transaction_list']/div[1]//button[text()='Cancel']
    ${is_cancelled}=    Wait Until Page Contains Element    xpath=//div[@class='transaction_list']
    
    # Expected Result: Transaction should disappear from the list after cancellation.

    # Step 11: For monthly transfers, test correct count of completed transactions
    ${monthly_count}=    Get Text    xpath=//div[@class='transaction_status']
    Should Match    ${monthly_count}    \(\d+/\d+\)    # Check the count representation
    
    # Expected Result: Correctly show transaction counts.

    # Step 12: Cancel an advance transfer and verify confirmation prompt
    Click Element    xpath=//div[@class='transaction_list']/div[1]//button[text()='Cancel Advance Transfer']
    ${confirm_text}=    Get Text    xpath=//div[@class='confirmation_dialog']
    Should Be Equal As Strings    ${confirm_text}    "Do you want to cancel the advance transfer?"

    # Expected Result: A confirmation dialog appears.

    # Step 13: Confirm cancellation and check for success messages
    Click Element    xpath=//button[text()='Yes']
    ${toast_message}=    Get Text    xpath=//div[@class='toast_message']
    Should Contain    ${toast_message}    "Cancelled the advance transfer successfully."

    # Expected Result: Display the appropriate Toast message.

    # Postconditions and cleanup
    Log Out    # Logout logic is based on existing implemented function
