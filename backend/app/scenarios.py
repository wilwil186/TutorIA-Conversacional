"""Static catalog of practice scenarios served to the client."""

from app.schemas import Scenario

SCENARIOS: list[Scenario] = [
    Scenario(
        id="small_talk",
        title="Small talk",
        description="Casual conversation: greetings, hobbies, weekend plans.",
        expected_topic="everyday casual conversation and getting to know each other",
    ),
    Scenario(
        id="restaurant",
        title="At a restaurant",
        description="Order food, ask about the menu, and pay the bill.",
        expected_topic="ordering food and interacting with a waiter at a restaurant",
    ),
    Scenario(
        id="travel",
        title="Travel & directions",
        description="Ask for directions, buy tickets, check in at a hotel.",
        expected_topic="traveling, asking for directions, and transport",
    ),
    Scenario(
        id="job_interview",
        title="Job interview",
        description="Answer common interview questions and talk about your experience.",
        expected_topic="a professional job interview",
    ),
    Scenario(
        id="shopping",
        title="Shopping",
        description="Ask for sizes and prices, try things on, and pay.",
        expected_topic="shopping for clothes or goods in a store",
    ),
]
