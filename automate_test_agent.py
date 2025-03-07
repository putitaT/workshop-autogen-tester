import os
import asyncio
from autogen_ext.models.openai import OpenAIChatCompletionClient
from autogen_core.models import ModelInfo, ModelFamily, SystemMessage, UserMessage, AssistantMessage
from autogen_agentchat.agents import AssistantAgent, SocietyOfMindAgent, CodeExecutorAgent
from autogen_agentchat.ui import Console
import aiohttp
from pathlib import Path
from autogen_agentchat.conditions import MaxMessageTermination, TextMentionTermination, TokenUsageTermination
from autogen_agentchat.teams import RoundRobinGroupChat
import re
from autogen_core import Image
from autogen_agentchat.messages import MultiModalMessage
from autogen_ext.code_executors.docker import DockerCommandLineCodeExecutor
import json

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
        Your role is to retrieve UI detail from `analyze_ui_agent`'.  
        ***IMPORTANT***
        - do not change any data from `analyze_ui_agent`
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
        - **Every line of code provided must be fully implemented in the `.robot` file. No part of the test case should be omitted.**

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

    tester_agent = AssistantAgent(
        name="robot_agent",
        model_client=model_client,
        system_message = """
        You are an expert tester specializing in writing test cases using Robot Framework. Your role is to generate `.robot` test scripts based on the structured test cases provided by `test_case_agent`.

        ### **Responsibilities:**
        - Retrieve test cases from `test_case_agent`.
        - Convert each test case into a well-structured **Robot Framework** test script.
        - Ensure that test steps follow the correct Robot Framework syntax.
        - Use **clear and meaningful keywords** to improve test readability.
        - Include necessary **setup and teardown** steps where applicable.
        - Ensure the script follows Robot Framework's best practices.

        ---

        ### **Test Case Structure in Robot Framework**
        For each test case, the script should contain:

        1. **Settings Section**  
        - Include required libraries (e.g., SeleniumLibrary, RequestsLibrary, BuiltIn, etc.).
        - Specify necessary resource files if applicable.

        2. **Variables Section**  
        - Define variables for UI elements, credentials, URLs, or reusable values.

        3. **Test Cases Section**  
        - Convert the structured test steps from `test_case_agent` into Robot Framework format.
        - Use **exact UI element names** as mentioned in `ui_agent`.
        - Ensure all **expected results** are properly asserted.

        ---

        ### **Example Robot Framework Test Case**
        If `test_case_agent` provides the following:
        Then, the Robot Framework script should look like this:
        
        ### **Additional Instructions**
        - Ensure test cases follow a **clear and consistent** structure.
        - If a step is unclear or an element is missing, **log a warning** instead of making assumptions.
        - Maintain proper indentation and readability in `.robot` files.
        - Avoid hardcoded values where possible, use variables for better maintainability.
        - **If any required details are missing**, notify the team before proceeding.

        Your goal is to generate **high-quality, maintainable, and executable** Robot Framework test scripts based on the provided test cases.
        """
    )

    docker_code_excutor = DockerCommandLineCodeExecutor(work_dir="robot-framework", image="ppodgorsek/robot-framework")
    await docker_code_excutor.start()

    code_executor = CodeExecutorAgent(
        name="code_executor",
        code_executor=docker_code_excutor
    )

    team = RoundRobinGroupChat(
        participants=[userstory_agent, ui_agent, test_case_agent, tester_agent, code_executor],
        max_turns=5
    )

    stream = team.run_stream(task="provide testcase for story_id 1002")
    await Console(stream)


asyncio.run(main())
