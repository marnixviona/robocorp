*** Settings ***
Documentation       Robot reads orders file and completes all orders in the file. It saves each order HTML receipt as a PDF file. It saves a screenshot of each of the ordered robots. It embeds the screenshot of the robot to the PDF receipt. It creates a ZIP archive of the PDF receipts and stores it in the output directory.

Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.FileSystem


*** Tasks ***
Read orders file and complete all orders in the file. Save each order HTML receipt as a PDF file. Save a screenshot of each of the ordered robots. Embed the screenshot of the robot to the PDF receipt. Create a ZIP archive of the PDF receipts and stores it in the output directory.
    Open the website
    Complete orders using the data from the orders file
    Create a ZIP file


*** Keywords ***
Open the website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    Close the annoying modal

Download the orders file and return
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${orders}=    Read table from CSV
    ...    orders.csv
    ...    header=True
    RETURN    ${orders}

Complete orders using the data from the orders file
    ${orders}=    Download the orders file and return
    FOR    ${order}    IN    @{orders}
        Order robot    ${order}
    END

Order robot
    [Arguments]    ${order}
    ${boolean}=    Set Variable    ${False}
    WHILE    ${boolean} == ${False}
        Select From List By Index    head    ${order}[Head]
        Click Button    id-body-${order}[Body]
        Input Text    xpath=//*[@id[starts-with(., '${1679}')]]    ${order}[Legs]
        Input Text    address    ${order}[Address]
        Click Button    preview
        Set Window Size    3000    3000
        ${screenshot}=    Take a screenshot of the robot    ${order}[Order number]
        Click Button    order
        ${boolean}=    Does Page Contain Button    order-another
    END

    ${pdf}=    Store the receipt as a PDF file    ${order}[Order number]
    Embed the robot screenshot to the receipt PDF file    ${order}[Order number]
    Click Button    order-another
    Close the annoying modal

Close the annoying modal
    Click Button    css:#root > div > div.modal > div > div > div > div > div > button.btn.btn-dark

Store the receipt as a PDF file
    [Arguments]    ${number}
    Wait Until Element Is Visible    receipt
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}receipt_${number}.pdf

Take a screenshot of the robot
    [Arguments]    ${number}
    Screenshot
    ...    xpath=//*[@id="robot-preview-image"]
    ...    ${OUTPUT_DIR}${/}screenshots${/}screenshot_${number}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${number}
    Open Pdf    ${OUTPUT_DIR}${/}receipt_${number}.pdf
    Add Watermark Image To Pdf
    ...    ${OUTPUT_DIR}${/}screenshots${/}screenshot_${number}.png
    ...    ${OUTPUT_DIR}${/}receipt_${number}.pdf
    Close Pdf    ${OUTPUT_DIR}${/}receipt_${number}.pdf

Create a ZIP file
    Archive Folder With Zip    ${OUTPUT_DIR}    receipts.zip    include=*.pdf
    Move File    %{ROBOT_ROOT}${/}receipts.zip    ${OUTPUT_DIR}    ${True}
