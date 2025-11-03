Situation: We need to commit the work we have locally so that we can do a new task in a parallel track.

Requirements: We need to analyze the code changes for the code base. Not just the files changed or how much they are change, but the actual logic within the changes. Use of a table or other structure to create complex object mappings and valuations is most likely useful to constuct an effective snapshot to organize the commits around.

Success Condition: We have analyzed the code base and constructed a relational understanding of the changes. You are able to then, using the data collected, costruct a prompt. The prompt will spell out the instructions for yourself to transform the data artifacts into details and organized commits in a proper logically sound sequence. You will then adhere to your constructed prompt and follow your own directions.

Output: A repo that has all of the staged and unstaged changes from the original condition either committed or discarded and a means to validate the start state against the end state and verify whether changes were lost.

Notes: I believe a stash of the start state and a log of discards or modified changes would be a straight forward way to compare the start state to the end state for validations.
