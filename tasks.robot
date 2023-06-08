*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.Calendar
Library             RPA.Windows
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.FileSystem

Task Timeout        1 min


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Dowload the csv file
    ${data}=    Read the data from csv file
    Fill all the orders    ${data}
    Create ZIP package from PDF files
    [Teardown]    Cleanup


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    Wait Until Page Contains Element    css:.btn.btn-danger

Close the annoying modal by clicking I guess so
    Click Button    css:.btn.btn-danger

Dowload the csv file
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=true

Read the data from csv file
    ${table}=    Read table from CSV    orders.csv
    RETURN    ${table}

Fill the form for one robot
    [Arguments]    ${order}
    Select From List By Value    head    ${order}[Head]
    Click Element    id-body-1
    Input Text    class:form-control    ${order}[Legs]
    Input Text    address    ${order}[Address]
    Click Button    preview
    Click Button    order
    Page Should Not Contain Element    class:alert-danger

Fill all the orders
    [Arguments]    ${data}
    FOR    ${order}    IN    @{data}
        Close the annoying modal by clicking I guess so
        Wait Until Keyword Succeeds    1 min    0.5 sec    Fill the form for one robot    ${order}
        Wait Until Page Contains Element    order-another
        ${pdf}=    Store the receipt as a PDF file    ${order}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${order}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Click Button    order-another
    END

Store the receipt as a PDF file
    [Arguments]    ${OrderNumber}
    Html To Pdf    ${OrderNumber}    ${OUTPUT_DIR}${/}receipts${/}orderNumber${OrderNumber}.pdf
    RETURN    ${OUTPUT_DIR}${/}receipts${/}orderNumber${OrderNumber}.pdf

Take a screenshot of the robot
    [Arguments]    ${orderNUmber}
    RPA.Browser.Selenium.Screenshot
    ...    robot-preview-image
    ...    ${OUTPUT_DIR}${/}screenshots${/}screenShotNumber${OrderNumber}.png
    RETURN    ${OUTPUT_DIR}${/}screenshots${/}screenShotNumber${OrderNumber}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    Add Watermark Image To Pdf    ${screenshot}    ${pdf}
    Close Pdf

Create ZIP package from PDF files
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}${/}PDFs.zip
    Archive Folder With zip    ${OUTPUT_DIR}${/}receipts    ${zip_file_name}

Cleanup
    Close Browser
    Remove Directory    ${OUTPUT_DIR}${/}receipts    True
    Remove Directory    ${OUTPUT_DIR}${/}screenshots    True
