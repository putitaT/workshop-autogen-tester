import os
import asyncio
from autogen_ext.models.openai import OpenAIChatCompletionClient
from autogen_core.models import ModelInfo, ModelFamily, SystemMessage, UserMessage, AssistantMessage
from autogen_agentchat.agents import AssistantAgent, SocietyOfMindAgent
from autogen_agentchat.ui import Console
import aiohttp
from pathlib import Path
from autogen_agentchat.conditions import MaxMessageTermination, TextMentionTermination, TokenUsageTermination
from autogen_agentchat.teams import RoundRobinGroupChat
import re
from autogen_core import Image
from autogen_agentchat.messages import MultiModalMessage
import json
import pandas as pd

async def get_user_story() -> any:
    api_url = "https://poc-ba-helper-service-3484833342.asia-southeast1.run.app/api/v1/userstory"

    async with aiohttp.ClientSession(connector=aiohttp.TCPConnector(ssl=False)) as session:
        async with session.get(api_url) as response:
            if response.status == 200:
                data = await response.json()
                return data
            else:
                return {"error": f"Failed to fetch user story, status code: {response.status}"}
            
async def call_vision_agent() -> any:
    analyze_ui_agent = AssistantAgent(
        name="analyze_ui_agent",
        model_client=OpenAIChatCompletionClient(model="gpt-4o-mini"),
        system_message="""
        You are a UX/UI Designer. Your role is to provide an extremely detailed explanation of every UI element in the given image. 
        
        **Instructions:**
        - Describe **every visible UI element**, including buttons, icons, text labels, input fields, tables, images, and any other components.
        - **Use the exact text** from the image when referring to buttons, labels, or any visible content.
        - Explain the **purpose and functionality** of each element, including what happens when a user interacts with it.
        - If an element appears interactive (e.g., a button, dropdown, or link), describe its expected behavior.
        - Mention **groupings or sections** (e.g., navigation bar, forms, popups, tables) and how they relate to the overall UI.
        - If an element appears disabled, hidden, or inactive, state that explicitly.
        - If the UI includes **icons or graphical indicators**, explain their meaning.

        **Goal:**  
        Provide a thorough breakdown so that even someone who has never seen this UI before can understand all components and their interactions just by reading your explanation.
        """
    )

    message = MultiModalMessage(
        content=[
            "You are a UI analyst. Explain every element in this image in detail, including all visible components and related functions.",
            Image.from_file("/Users/a677231/workspace/tester-helper-agent/document/picture/ibank_advance_tranfer_list.png")
        ],
        source="analyze_ui_agent",
    )

    vision_stream = analyze_ui_agent.run_stream(task=message)

    result = []
    async for response in vision_stream:
        if hasattr(response, "content"):
            result.append(response.content)

    return result[1]

async def generate_excel(test_cases: list) -> str:
    df = pd.DataFrame(
        [{
            "No TC.": test["test_case_id"],
            "Test Description": test["test_description"],
            "Test Step": test["test_steps"],
            "Test Expected": test["expected_result"]
        } for test in test_cases]
    )

    # Save DataFrame to an Excel file
    excel_filename = "test_cases.xlsx"
    df.to_excel(excel_filename, index=False)

    print(f"✅ Excel file '{excel_filename}' has been generated successfully.")


async def main():
    # model_client = OpenAIChatCompletionClient(
    #     model="llama3.2:latest",
    #     base_url=os.environ["OLLAMA_BASE_URL"],
    #     api_key=os.environ["OPENAI_API_KEY"],
    #     model_info=ModelInfo(
    #         vision=False,
    #         function_calling=True,
    #         json_output=False,
    #         family=ModelFamily.UNKNOWN
    #     )
    # )

    model_client = OpenAIChatCompletionClient(model="gpt-4o-mini")

    userstory_agent = AssistantAgent(
        name="userstory_agent",
        model_client=model_client,
        system_message="""
        Your role is to retrieve User Story data from the API'.  
            - Fetch relevant data from the API. 
            - Structure the data clearly and provide it to `test_case_agent`.  
            - If the data is incomplete, inform `test_case_agent` that there may be errors or missing information.  
        """,
        tools=[get_user_story]
    )


    ui_agent = AssistantAgent(
        name="ui_agent",
        model_client=model_client,
        system_message="""
        Your role is to retrieve UI detail from `call_vision_agent`'.  
        ***IMPORTANT***
        - do not change any data from `call_vision_agent`
        """,
        tools=[call_vision_agent]
    )
    
    test_case_agent = AssistantAgent(
        name="test_case_agent",
        model_client=model_client,
        system_message = """
        You are a senior tester specializing in writing comprehensive test cases based on user stories and UI details.

        **Responsibilities:**
        - Retrieve user story details from `userstory_agent` to understand the feature requirements.
        - Retrieve UI details from `ui_agent` to analyze the user interface interactions.
        - Write well-structured test cases that ensure the correct functionality of the feature.

        **Test Case Structure:**
            ### Test Case ID: TC_[story_id]_[index]
            1. **Test Title**: A concise summary of the test case.
            2. **Test Description**: A detailed explanation of the scenario being tested.
            3. **Test Steps**:
            - Identify UI elements from `ui_agent` that need interaction.
            - Provide a step-by-step guide on what actions the user should take.
            - When explaining the steps to test must enter button name, field input name and text that display.
            4. **Expected Result**: The expected outcome if the feature is working correctly.
        ************************

        **Additional Instructions:**
        - Ensure all test steps align with the UI flow provided by `ui_agent`.
        - Validate that the test case fully covers the acceptance criteria from `userstory_agent`.
        - Clearly state any assumptions or dependencies.
        - If any information is missing or unclear, notify the team before proceeding.

        Your goal is to create precise and actionable test cases to ensure high-quality testing coverage. by using above test case structure 
        to response user
        """,
    )

    translator_agent = AssistantAgent(
        name="translator_agent",
        model_client=model_client,
        system_message="""
        Your responsibility is to translate the Testcase received from `test_case_agent` into Thai.
        
        **Translation Guidelines:**
        1. Translate the content into formal and easy-to-read Thai.
        2. No need to translate specific words and technical terms such as function names, testcase name, software-related terminology, and words that should not be translated 
        (e.g., "Test Case ID", "Test Title", "Test Description", "User Name", "Test Steps", "Expected Result") **USE ENGLISH AS USUAL**.
        3. Maintain the structure of the User Story and do not alter the original content.
        4. Avoid translations that could introduce ambiguity or change the meaning.
        
        **Notes:**
        - If unsure whether a term should be translated, retain the original term in parentheses.
        """
    )

    tranform_agent = AssistantAgent(
        name="tranform_agent",
        model_client=model_client,
        system_message = """
        You are responsible for transforming the translated test case received from `translator_agent` into a structured JSON format.
        The output will be passed to the `generate_excel_agent` for generate to excel.

        **Transformation Rules:**
        1. Convert the translated test cases into a **list of JSON objects**.
        2. ***IMPORTANT*** Do not change the information obtained from `translator_agent`
        2. Each test case must follow this format:

        ```json
        [
            {
                "test_case_id": "TC_[story_id]_[index]",
                "test_title": "Test Title",
                "test_description": "Test Description",
                "test_steps": "1. User clicks on the 'Login' button\n2. User enters 'username' and 'password' into the login form\n3. User clicks 'Submit' button\n4. System processes the authentication\n5. User is redirected to the dashboard",
                "expected_result": "The system should correctly authenticate and display the user's dashboard"
            },
            {
                "test_case_id": "TC_[story_id]_[index]",
                "test_title": "Test Title 2",
                "test_description": "Test Description 2",
                "test_steps": "1. User clicks 'Forgot Password' link\n2. System prompts for email\n3. User enters registered email and clicks 'Submit'\n4. System sends a password reset link to the email\n5. User receives an email and follows the link",
                "expected_result": "User should be able to reset their password successfully"
            }
        ]
        """
    )

    generate_excel_agent = AssistantAgent(
        name="generate_excel_agent",
        model_client=model_client,
        system_message="""
        Your role is to generate excel from `tranform_agent`'.  
        ***IMPORTANT***
        - do not change any data from `tranform_agent`
        """,
        tools=[generate_excel]
    )

    team = RoundRobinGroupChat(
        participants=[userstory_agent, ui_agent, test_case_agent],
        max_turns=3
    )

    society_of_mind_agent = SocietyOfMindAgent(
        name="society_of_mind_agent",
        description="do not change any data from team agent",
        team=team,
        model_client=model_client
    )

    final_team = RoundRobinGroupChat(
        participants=[society_of_mind_agent, translator_agent, tranform_agent, generate_excel_agent],
        max_turns=4,
    )

    stream = final_team.run_stream(task="provide testcase for story_id 1002")
    await Console(stream)


asyncio.run(main())
