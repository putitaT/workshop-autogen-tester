*** Settings ***
Library           SeleniumLibrary

*** Variables ***
${LOGIN_PAGE}    https://ibank.example.com/login
${ADVANCE_TRANSFER_LIST}    //path/to/advance/transfer/list
${ACCOUNT_NUMBER}    //path/to/user/account/number
${DESTINATION_ACCOUNT}    //path/to/destination/account/number
${TRANSACTION_DETAILS}    //path/to/transaction/details
${CANCEL_BUTTON}    //path/to/cancel/button
${TOAST_MESSAGE}    //path/to/toast/message

*** Test Cases ***
TC_1002_01: Account Number Display Settings
    [Documentation]    Verify the display settings of the account number for the user's own account.
    Open Browser    ${LOGIN_PAGE}    Chrome
    Input Text    //input[@name='username']    valid_username
    Input Text    //input[@name='password']    valid_password
    Click Button    //button[text()='Login']
    Go To    ${ADVANCE_TRANSFER_LIST}
    ${displayed_account_number}=    Get Text    ${ACCOUNT_NUMBER}
    Should Not Be Empty    ${displayed_account_number}

TC_1002_02: Display of Destination Account Number
    [Documentation]    Verify the display settings of the destination account number.
    Open Browser    ${LOGIN_PAGE}    Chrome
    Input Text    //input[@name='username']    valid_username
    Input Text    //input[@name='password']    valid_password
    Click Button    //button[text()='Login']
    Go To    ${ADVANCE_TRANSFER_LIST}
    ${destination_account}=    Get Text    ${DESTINATION_ACCOUNT}
    Should Be Equal As Strings    ${destination_account}    Last Four Digits Only

TC_1002_03: Display Transaction Data
    [Documentation]    Ensure that transaction data is displayed according to the bank's data.
    Open Browser    ${LOGIN_PAGE}    Chrome
    Input Text    //input[@name='username']    valid_username
    Input Text    //input[@name='password']    valid_password
    Click Button    //button[text()='Login']
    Go To    ${ADVANCE_TRANSFER_LIST}
    ${transaction_data}=    Get Text    ${TRANSACTION_DETAILS}
    Should Not Be Empty    ${transaction_data}

TC_1002_04: Maximum Number of Transactions
    [Documentation]    Verify the maximum number of advance transactions displayed.
    Open Browser    ${LOGIN_PAGE}    Chrome
    Input Text    //input[@name='username']    valid_username
    Input Text    //input[@name='password']    valid_password
    Click Button    //button[text()='Login']
    Go To    ${ADVANCE_TRANSFER_LIST}
    ${transaction_count}=    Get Element Count    //path/to/transaction/item
    Should Be Less Than Or Equal To    ${transaction_count}    100

TC_1002_05: Sorting of Transactions
    [Documentation]    Validate the sorting functionality of the transaction list.
    Open Browser    ${LOGIN_PAGE}    Chrome
    Input Text    //input[@name='username']    valid_username
    Input Text    //input[@name='password']    valid_password
    Click Button    //button[text()='Login']
    Go To    ${ADVANCE_TRANSFER_LIST}
    ${sorted_dates}=    Get Text    //path/to/sorted/date
    Should Be Sorted    ${sorted_dates}

TC_1002_06: View Transaction Details
    [Documentation]    Ensure users can view details of individual transactions.
    Open Browser    ${LOGIN_PAGE}    Chrome
    Input Text    //input[@name='username']    valid_username
    Input Text    //input[@name='password']    valid_password
    Click Button    //button[text()='Login']
    Go To    ${ADVANCE_TRANSFER_LIST}
    Click Button    ${CANCEL_BUTTON}
    ${details}=    Get Text    ${TRANSACTION_DETAILS}
    Should Not Be Empty    ${details}

TC_1002_07: Currency Format
    [Documentation]    Check the display format of monetary values.
    Open Browser    ${LOGIN_PAGE}    Chrome
    Input Text    //input[@name='username']    valid_username
    Input Text    //input[@name='password']    valid_password
    Click Button    //button[text()='Login']
    Go To    ${ADVANCE_TRANSFER_LIST}
    ${currency_display}=    Get Text    //path/to/currency/format
    Should Match Regexp    ${currency_display}    \d{1,3}(,\d{3})*\.\d{2}

TC_1002_08: Single Advance Transaction Completion
    [Documentation]    Verify that single advance transactions disappear upon completion.
    Open Browser    ${LOGIN_PAGE}    Chrome
    Input Text    //input[@name='username']    valid_username
    Input Text    //input[@name='password']    valid_password
    Click Button    //button[text()='Login']
    Go To    ${ADVANCE_TRANSFER_LIST}
    Sleep    60    # Wait for the effective transfer date
    ${transaction_count_after}=    Get Element Count    //path/to/transaction/item
    Should Be Equal As Numbers    ${transaction_count_after}    0

TC_1002_09: Monthly Advance Transaction Tracking
    [Documentation]    Ensure proper tracking of monthly advance transactions.
    Open Browser    ${LOGIN_PAGE}    Chrome
    Input Text    //input[@name='username']    valid_username
    Input Text    //input[@name='password']    valid_password
    Click Button    //button[text()='Login']
    Go To    ${ADVANCE_TRANSFER_LIST}
    Sleep    60    # Wait for the effective transfer date
    ${trans_time}=    Get Text    //path/to/trans_time
    Should Not Be Empty    ${trans_time}

TC_1002_10: Canceling a Scheduled Transfer
    [Documentation]    Verify cancellation of a scheduled advance transfer.
    Open Browser    ${LOGIN_PAGE}    Chrome
    Input Text    //input[@name='username']    valid_username
    Input Text    //input[@name='password']    valid_password
    Click Button    //button[text()='Login']
    Go To    ${ADVANCE_TRANSFER_LIST}
    Click Button    ${CANCEL_BUTTON}
    ${confirmation}=    Get Text    //path/to/confirmation/message
    Should Be Equal As Strings    ${confirmation}    "Do you want to cancel the scheduled transfer?"
    Click Button    //button[text()='Yes']
    ${toast_message}=    Get Text    ${TOAST_MESSAGE}
    Should Match    ${toast_message}    "Successfully canceled the scheduled transfer|Failed to cancel the scheduled transfer"
    
*** Teardown ***
Close Browser
