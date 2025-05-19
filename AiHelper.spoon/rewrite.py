#!/usr/bin/env python3
import cohere
import sys
import os

api_key = os.environ.get("COHERE_API_KEY")
text = os.environ.get("TEXT")
mode = os.environ.get("MODE")

print("Using API key:", api_key, file=sys.stderr)

if not api_key:
    print("Missing COHERE_API_KEY environment variable", file=sys.stderr)
    sys.exit(1)


print("Input text length:", len(text), file=sys.stderr)

if not text:
    print("Input text is empty", file=sys.stderr)
    sys.exit(1)

co = cohere.Client(api_key)

# function that based on the mode will generate a prompt for the cohere API
def generate_prompt(mode, text):
    if mode == "rewrite":
        return f"Please rewrite this text to improve clarity, grammar, and flow. Please only provide the improved text. The text will either be in english or danish. Input:\n\n{text}"
    elif mode == "summarize":
        return f"Please summarize this text. Please only provide the summary. The text will either be in english or danish. Input:\n\n{text}"
    elif mode == "translate":
        return f"Please translate this text to danish. Please only provide the translation. The text will either be in english or danish. Input:\n\n{text}"
    elif mode == "translate_to_english":
        return f"Please translate this text to english. Please only provide the translation. The text will either be in english or danish. Input:\n\n{text}"
    else:
        raise ValueError("Invalid mode")
    
response = co.generate(
    model='command-r-plus',
    prompt=generate_prompt(mode, text),
    temperature=0.7,
)

print(response.generations[0].text.strip())
