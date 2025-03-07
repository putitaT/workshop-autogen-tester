*** Settings ***
Library           SeleniumLibrary
Library           BuiltIn

*** Variables ***
${BASE_URL}      https://your-ibank-application-url.com
${USERNAME}      your_username
${PASSWORD}      your_password
${CHEVRON_BUTTON}    xpath=//button[@class='chevron']  # Update with the actual locator
${CANCEL_BUTTON}     xpath=//button[@class='cancel']  # Update with the actual locator
${CONFIRM_YES}       xpath=//button[text()='ใช่']  # Update with the actual locator
${CONFIRM_NO}        xpath=//button[text()='ไม่ใช่'] # Update with the actual locator

*** Test Cases ***
Verify Account Number Display
    [Documentation]    Ensure that the account number for the user's account is displayed according to the user's settings regarding its visibility.
    Log In To Ibank Application
    Navigate To Advance Transfer Transaction List
    ${result}=    Get Account Number Display
    Should Not Be Empty    ${result}

Ensure Last Four Digits are Displayed When Account Number is Hidden
    [Documentation]    Verify that when the full account number visibility is hidden, only the last four digits are shown.
    Log In To Ibank Application
    Navigate To Advance Transfer Transaction List
    ${result}=    Get Last Four Digits Display
    Should Not Be Empty    ${result}
    Should Match    ${result}    4 digits format

Verify Destination Account Number is Always Hidden
    [Documentation]    Check that the destination account number is not displayed in any case.
    Log In To Ibank Application
    Navigate To Advance Transfer Transaction List
    ${destination_account}=    Get Destination Account Number Display
    Should Be Empty    ${destination_account}

Verify Maximum Transactions Displayed
    [Documentation]    Check that at most 100 advance transaction records are displayed when more than 100 have been processed.
    Log In To Ibank Application
    Navigate To Advance Transfer Transaction List
    ${count}=    Get Transaction Count
    Should Be Less Than Or Equal    ${count}    100

Validate Sorting of Transactions
    [Documentation]    Ensure transactions are sorted by the effective transfer date and then by the created date.
    Log In To Ibank Application
    Navigate To Advance Transfer Transaction List
    ${sorted}=    Verify Transaction Sorting
    Should Be True    ${sorted}

Check Viewing of Transaction Details
    [Documentation]    Verify that users can view details of advance transactions by selecting them from the list.
    Log In To Ibank Application
    Navigate To Advance Transfer Transaction List
    Click Element    ${CHEVRON_BUTTON}
    ${details_displayed}=    Is Element Visible    xpath=//div[@class='transaction-details']  # Update with actual locator
    Should Be True    ${details_displayed}

Confirm Currency Format of Amounts
    [Documentation]    Validate that transaction amounts are displayed in the standard currency format.
    Log In To Ibank Application
    Navigate To Advance Transfer Transaction List
    ${amount_format}=    Get Currency Format
    Should Match    ${amount_format}    \d{1,3}(,\d{3})*(\.\d{2})?  # Matches the format "1,000.00"

Check One-Time Advance Transactions Disappearance
    [Documentation]    Ensure one-time advance transactions vanish from the list on their scheduled transfer date.
    Log In To Ibank Application
    Navigate To Advance Transfer Transaction List
    ${transaction_found}=    Check One-Time Transaction Disappearance
    Should Be False    ${transaction_found}

Validate Monthly Advance Transactions Update
    [Documentation]    Check if monthly advance transactions are updated correctly after the scheduled transfer date.
    Log In To Ibank Application
    Navigate To Advance Transfer Transaction List
    ${monthly_update_status}=    Check Monthly Update Status
    Should Be True    ${monthly_update_status}

Ensure Cancel Advance Transaction Prompts Confirmation
    [Documentation]    Verify that clicking on "Cancel Advance Transfer" shows a confirmation dialog.
    Log In To Ibank Application
    Navigate To Advance Transfer Transaction List
    Click Element    ${CANCEL_BUTTON}
    ${confirmation_displayed}=    Is Element Visible    xpath=//div[@class='confirmation-dialog']  # Confirm actual locator
    Should Be True    ${confirmation_displayed}

Confirm Success Toast on Advance Transaction Cancellation
    [Documentation]    Ensure a successful cancellation of an advance transaction triggers a success message.
    Log In To Ibank Application
    Navigate To Advance Transfer Transaction List
    Click Element    ${CANCEL_BUTTON}
    Click Element    ${CONFIRM_YES}
    ${toast}=    Get Toast Message
    Should Be Equal As Strings    ${toast}    'ยกเลิกรายการโอนล่วงหน้าสำเร็จ'

Validate Failure Toast on Unsuccessful Cancellation
    [Documentation]    Ensure that a failure in cancellation shows the appropriate error message.
    Simulate Failure Scenario
    Log In To Ibank Application
    Navigate To Advance Transfer Transaction List
    Click Element    ${CANCEL_BUTTON}
    Click Element    ${CONFIRM_YES}
    ${error_toast}=    Get Toast Message
    Should Be Equal As Strings    ${error_toast}    'ยกเลิกรายการล่วงหน้าไม่สำเร็จ'

*** Keywords ***
Log In To Ibank Application
    Open Browser    ${BASE_URL}    Chrome
    Input Text    id=username    ${USERNAME}
    Input Text    id=password    ${PASSWORD}
    Click Button    id=login-button
    Title Should Be    ibank Home

Navigate To Advance Transfer Transaction List
    Click Link    л//a[text()='Advance Transfer Transaction List']  # Update with actual locator

Get Account Number Display
    # Implement logic to get and return the account number display

Get Last Four Digits Display
    # Implement logic to check and return last four digits of the account number

Get Destination Account Number Display
    # Implement logic to confirm if the destination account number is displayed

Get Transaction Count
    # Implement logic to get the count of displayed transactions

Verify Transaction Sorting
    # Implement logic to verify sorting of transactions

Check One-Time Transaction Disappearance
    # Implement logic to confirm if the transaction is absent

Check Monthly Update Status
    # Implement logic to check for monthly update status

Get Toast Message
    # Implement logic to get the displayed toast message

Simulate Failure Scenario
    # Implement logic to simulate cancellation failure
