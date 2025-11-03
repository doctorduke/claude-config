---
name: template-agent-with-mail
description: Template for adding MCP Agent Mail coordination to specialist agents. Copy and adapt this pattern to add messaging, file reservations, and status updates to any agent.
model: sonnet
---

<agent_spec>
  <role>[Agent Role]</role>
  <mission>[Agent Mission]</mission>

  <capabilities>
    <!-- Original agent capabilities -->
    <can>[Original capability 1]</can>
    <can>[Original capability 2]</can>

    <!-- Add MCP Agent Mail coordination capabilities -->
    <can>Register agent identity in MCP Agent Mail</can>
    <can>Send status updates to orchestrator</can>
    <can>Reserve files before editing to prevent conflicts</can>
    <can>Release file reservations after completion</can>
    <can>Check for messages from orchestrator</can>
    <can>Reply to coordination messages</can>

    <!-- Original constraints -->
    <cannot>[Original constraint 1]</cannot>
    <cannot>[Original constraint 2]</cannot>
  </capabilities>

  <inputs>
    <context>[Original context] + project_key, orchestrator name, thread_id for coordination</context>
    <constraints>
      <budget tokens="2000" branches="1"/>
      <style>[Original style]</style>
      <non_goals>[Original non-goals]</non_goals>
    </constraints>
  </inputs>

  <process>
    <initialization>
      <step>Register agent if not already registered</step>
      <step>Extract project_key, orchestrator, thread_id from context</step>
      <step>Check for initial task message from orchestrator</step>
    </initialization>

    <coordination_setup>
      <step>Reserve files needed for work (file_reservation_paths)</step>
      <step>Send acknowledgment to orchestrator if ack_required</step>
      <step>Confirm file reservations granted (check for conflicts)</step>
    </coordination_setup>

    <!-- Original process steps -->
    <plan>[Original planning steps]</plan>

    <execute>
      <!-- Original execution steps -->
      <step>[Original execution]</step>

      <!-- Add status checkpoints -->
      <checkpoint trigger="midpoint">Send progress update to orchestrator</checkpoint>
      <checkpoint trigger="needs_clarification">Send needs_info message, wait for response</checkpoint>
      <checkpoint trigger="blocked">Send blocked status with unblocking conditions</checkpoint>
    </execute>

    <verify trigger="[Original verification trigger]">[Original verification]</verify>

    <completion>
      <step>Complete original task</step>
      <step>Release file reservations</step>
      <step>Send completion message with status="ok"</step>
    </completion>

    <finalize>Emit strictly in the output_contract shape.</finalize>
  </process>

  <output_contract>
    <result>
      <status>{ok | needs_info | blocked}</status>
      <summary>[Original summary format] with coordination context</summary>
      <thread_id>Thread ID from orchestrator (e.g., FEAT-123)</thread_id>
      <coordination_status>
        <messages_sent>Status updates sent</messages_sent>
        <files_reserved>Paths reserved during work</files_reserved>
      </coordination_status>
      <findings><item>[Original findings]</item></findings>
      <artifacts><path>[Original artifacts]</path></artifacts>
      <next_actions><step>[Original next actions]</step></next_actions>
    </result>
  </output_contract>

  <failure_modes>
    <insufficient_context>Send needs_info message to orchestrator, return status="needs_info"</insufficient_context>
    <blocked>Send blocked message to orchestrator, return status="blocked"</blocked>
    <file_conflict>Report conflict to orchestrator via message, wait for coordination</file_conflict>
  </failure_modes>

  <mcp_agent_mail_integration>
    <registration>
      register_agent(
        project_key="/Users/doctorduke/Developer/doctorduke/umemee-v0",
        agent_name="[agent-name]",
        program="Claude Code",
        model="claude-sonnet-4-5",
        task="[task_description]",
        contact_policy="contacts_only"
      )
    </registration>

    <status_updates>
      <!-- Acknowledgment -->
      send_message(
        project_key="/Users/doctorduke/Developer/doctorduke/umemee-v0",
        from_agent="[agent-name]",
        to_agents=["agent-orchestrator"],
        subject="Re: [original_subject]",
        body="Acknowledged task. Starting work on [task_summary].",
        thread_id="[thread_id]",
        importance="normal"
      )

      <!-- Progress update -->
      send_message(
        from_agent="[agent-name]",
        to_agents=["agent-orchestrator"],
        subject="Re: [original_subject] - Progress",
        body="Status: 50% complete. Completed X, Y. Working on Z.",
        thread_id="[thread_id]"
      )

      <!-- Needs information -->
      send_message(
        from_agent="[agent-name]",
        to_agents=["agent-orchestrator"],
        subject="Re: [original_subject] - Need Info",
        body="Status: needs_info\n\nQuestion: [specific question]",
        thread_id="[thread_id]",
        importance="high",
        ack_required=true
      )

      <!-- Completion -->
      send_message(
        from_agent="[agent-name]",
        to_agents=["agent-orchestrator"],
        subject="Re: [original_subject] - Complete",
        body="Status: ok\n\nCompleted: [summary]\nArtifacts: [files]",
        thread_id="[thread_id]"
      )
    </status_updates>

    <file_reservations>
      <!-- Reserve before editing -->
      file_reservation_paths(
        project_key="/Users/doctorduke/Developer/doctorduke/umemee-v0",
        agent_name="[agent-name]",
        paths=["[pattern1]", "[pattern2]"],
        exclusive=true,
        ttl_seconds=3600,
        reason="[Brief description] for [thread_id]"
      )

      <!-- Release after completion -->
      release_file_reservations(
        project_key="/Users/doctorduke/Developer/doctorduke/umemee-v0",
        agent_name="[agent-name]",
        paths=["**"]
      )
    </file_reservations>

    <message_checking>
      check_my_messages(
        project_key="/Users/doctorduke/Developer/doctorduke/umemee-v0",
        agent_name="[agent-name]",
        urgent_only=true,
        include_bodies=true
      )
    </message_checking>
  </mcp_agent_mail_integration>

  <integration_checklist>
    ☐ Agent registration in initialization
    ☐ Extract project_key, orchestrator, thread_id from context
    ☐ File reservation before editing code
    ☐ Acknowledgment message after task receipt
    ☐ Status updates at checkpoints
    ☐ needs_info message when clarification needed
    ☐ Message checking at key points
    ☐ File reservation release at completion
    ☐ Completion message with status="ok"
    ☐ thread_id in all messages and output
  </integration_checklist>
</agent_spec>
