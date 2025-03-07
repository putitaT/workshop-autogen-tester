*** Settings ***
Library    SeleniumLibrary
Suite Setup    Open Browser    https://your-ibank-url.com    chrome
Suite Teardown    Close Browser

*** Variables ***
${ACCOUNT_OVERVIEW_PAGE}    xpath=//div[@id='account-overview']
${TRANSACTION_LIST_PAGE}    xpath=//div[@id='transaction-list']
${CANCEL_BUTTON}    xpath=//button[@id='cancel-transfer']
${TOAST_MESSAGE}    xpath=//div[@class='toast-message']

*** Test Cases ***
Validate Display of User Account Number
    [Documentation]    Ensure the account number of the user's account shows in full or part based on display settings.
    Log In To iBank Application
    Set Display Preferences    Full Account Number
    Go To Account Overview
    Should See Complete Account Number
    Set Display Preferences    Hide Account Number
    Go To Account Overview
    Should See Last Four Digits Only

Validate Display of Destination Account Number
    [Documentation]    Ensure the destination account number is always hidden except for the last 4 digits.
    Log In To iBank Application
    Attempt Transfer To Destination Account
    Should See Hidden Destination Account Number

Validate Number of Transactions Displayed
    [Documentation]    Check if a maximum of 100 advance transactions are displayed.
    Log In To iBank Application
    Navigate To Advance Transfer Transaction List
    Count Transactions Should Be At Most 100

Validate Transaction Sorting
    [Documentation]    Ensure the transactions are sorted by effective transfer date.
    Log In To iBank Application
    Navigate To Advance Transfer Transaction List
    Verify Transaction Sorting By Date

Validate Viewing Transaction Details
    [Documentation]    User should be able to view transaction details one at a time.
    Log In To iBank Application
    Navigate To Advance Transfer Transaction List
    View Transaction Detail For First Transaction
    View Transaction Detail For Second Transaction

Validate Currency Display Format
    [Documentation]    Ensure the amount is displayed in proper currency format.
    Log In To iBank Application
    Navigate To Advance Transfer Transaction List
    Should See Amounts In Proper Currency Format

Validate Transaction Removal for One-Time Transactions
    [Documentation]    Verify that a one-time transaction is removed from the list after its due date.
    Log In To iBank Application
    Navigate To Advance Transfer Transaction List
    Verify OneTimeTransactionRemovedAfterDueDate

Validate Monthly Transaction Counting
    [Documentation]    Ensure monthly transactions are counted correctly based on settings.
    Log In To iBank Application
    Set Up Monthly Transaction
    Wait For Due Date
    Verify Monthly Transaction Count Displayed

Validate Cancel Advance Transfer Prompt
    [Documentation]    Check the prompt when cancelling an advance transfer.
    Log In To iBank Application
    Click Cancel Transfer Button
    Should See Cancellation Prompt

Validate Successful Cancellation
    [Documentation]    Confirm that successfully cancelling a transaction displays a success message.
    Log In To iBank Application
    Cancel Transfer Successfully
    Should See Toast Message With Success

Validate Unsuccessful Cancellation
    [Documentation]    Confirm that an unsuccessful cancellation displays an error message.
    Log In To iBank Application
    Attempt To Cancel Transfer Unsuccessfully
    Should See Toast Message With Error

*** Keywords ***
Log In To iBank Application
    [Documentation]    Log into the iBank application.
    # Implement login steps here

Set Display Preferences    
    [Arguments]    ${preference}
    [Documentation]    Change account display preferences to full or hide.
    # Implement steps here to navigate to settings and set the required preference

Go To Account Overview
    [Documentation]    Navigate back to the account overview page.
    Click Element    ${ACCOUNT_OVERVIEW_PAGE}

Should See Complete Account Number
    [Documentation]    Check if the full account number is displayed on the account overview.
    ${account_number}=    Get Text    xpath=//div[@class='account-number']
    Should Not Be Empty    ${account_number}

Should See Last Four Digits Only
    [Documentation]    Assert that only last four digits of account number is displayed.
    ${account_number}=    Get Text    xpath=//div[@class='account-number']
    Should Match Regexp    ${account_number}    \d{4}$

Attempt Transfer To Destination Account
    [Documentation]    Attempt to transfer money to the destination account.
    # Implement transfer steps here

Should See Hidden Destination Account Number
    [Documentation]    Validate if the destination account number is hidden.
    ${dest_account_number}=    Get Text    xpath=//div[@class='destination-account-number']
    Should Match Regexp    ${dest_account_number}    \d{4}$

Navigate To Advance Transfer Transaction List
    [Documentation]    Navigate to the advance transfer transaction list.
    # Implement navigation steps here

Count Transactions Should Be At Most 100
    [Documentation]    Check if transactions displayed are at most 100.
    ${transaction_count}=    Get Element Count    xpath=//div[@class='transaction']
    Should Be Less Than Or Equal    ${transaction_count}    100

Verify Transaction Sorting By Date
    [Documentation]    Ensure transactions are sorted by date.
    # Implement sorting validation steps here

View Transaction Detail For First Transaction
    [Documentation]    View detailed information for the first transaction.
    Click Element    xpath=//div[@class='transaction'][1]//button[@class='chevron']

View Transaction Detail For Second Transaction
    [Documentation]    View detailed information for the second transaction.
    Click Element    xpath=//div[@class='transaction'][2]//button[@class='chevron']

Should See Amounts In Proper Currency Format
    [Documentation]    Check if amounts are displayed in proper currency format.
    # Implement steps to validate the currency format here

Verify OneTimeTransactionRemovedAfterDueDate
    [Documentation]    Confirm that a one-time transaction is removed after due date.
    # Implement steps to check if the transaction is removed

Set Up Monthly Transaction
    [Documentation]    Setup a monthly transaction.
    # Implement transaction setup here

Wait For Due Date
    [Documentation]    Wait until the due date of the transaction.
    # Implement steps to wait for the due date

Verify Monthly Transaction Count Displayed
    [Documentation]    Validate the monthly transaction count displayed.
    # Implement count verification steps here

Click Cancel Transfer Button
    [Documentation]    Click the button to cancel an advance transfer.
    Click Element    ${CANCEL_BUTTON}

Should See Cancellation Prompt
    [Documentation]    Validate the appearance of a cancellation confirmation prompt.
    ${prompt_text}=    Get Text    xpath=//div[@class='cancel-confirmation']
    Should Be Equal    ${prompt_text}    “ต้องการยกเลิกรายการโอนล่วงหน้า”

Cancel Transfer Successfully
    [Documentation]    Simulate a successful transfer cancellation.
    # Implement steps to confirm cancellation

Should See Toast Message With Success
    [Documentation]    Validate a success message is displayed after cancellation.
    ${toast_message}=    Get Text    ${TOAST_MESSAGE}
    Should Be Equal    ${toast_message}    'ยกเลิกรายการโอนล่วงหน้าสำเร็จ'

Attempt To Cancel Transfer Unsuccessfully
    [Documentation]    Simulate an unsuccessful cancellation attempt.
    # Implement steps to attempt a cancellation

Should See Toast Message With Error
    [Documentation]    Validate an error message is displayed after a failed cancellation.
    ${toast_message}=    Get Text    ${TOAST_MESSAGE}
    Should Be Equal    ${toast_message}    'ยกเลิกรายการล่วงหน้าไม่สำเร็จ'
