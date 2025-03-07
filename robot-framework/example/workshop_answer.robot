*** Settings ***
Library    SeleniumLibrary
Variables    Test_data.yaml
Suite Setup    Prepare Suite Setup
Suite Teardown    Close Browser
Test Setup    Prepare Test Data
Test Teardown    Log out

*** Variables ***
${Test_Data}

# Login Page
${lbl_login_logo}    //*[@class='login_logo' and text()='Swag Labs']
${inp_username}    //*[@data-test='username']
${inp_password}    //*[@data-test='password']
${btn_login}    //*[@data-test='login-button']

# Product Page
${lbl_product_title}    //*[@data-test='title' and text()='Products']
${btn_open_menu}    //*[@id='react-burger-menu-btn']
${btn_logout}    //*[@data-test='logout-sidebar-link']

*** Keywords ***
Prepare Suite Setup
    ${chrome_path}    Set Variable    ${CURDIR}/../../../chrome/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing
    ${chromedriver_path}    Set Variable    ${CURDIR}/../../../chrome/chromedriver
    Open Browser    https://www.saucedemo.com/    GC    options=binary_location="${chrome_path}"    executable_path=${chromedriver_path}
    Maximize Browser Window
    Wait Until Element Is Visible    ${lbl_login_logo}

Prepare Test Data
    Set Test Variable    ${Test_Data}    ${${TEST_NAME}}

# Login Page
Fill In Username
    [Arguments]    ${text}=${Test_Data.input_data.username}
    Wait Until Element Is Visible    ${inp_username}
    Input Text    ${inp_username}    ${text}

Fill In Password
    [Arguments]    ${text}=${Test_Data.input_data.password}
    Wait Until Element Is Visible    ${inp_password}
    Input Text    ${inp_password}    ${text}

Click Login
    Wait Until Element Is Visible    ${btn_login}
    Click Element    ${btn_login}
    
# Product Page
Verify Product Page
    Wait Until Element Is Visible    ${lbl_product_title}

Log out
    Wait Until Element Is Visible    ${btn_open_menu}
    Click Element    ${btn_open_menu}
    Wait Until Element Is Visible    ${btn_logout}
    Click Element    ${btn_logout}
    
*** Test Cases ***
Test_01
    Fill In Username
    Fill In Password
    Click Login
    Verify Product Page

Test_02
    Fill In Username
    Fill In Password
    Click Login
    Verify Product Page