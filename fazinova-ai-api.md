# Weekly Changelog for fazinova-ai-api

## Highlights
- **New Features**: Significant enhancements to the agent and project tools, including better agent instructions, localization support, and project management functionalities.
- **UX Improvements**: Updates in the UI for better clarity and information presentation in project stages and agent management.
- **API Enhancements**: Improved JSON responses and incorporation of new methods for better handling of various projects and agents.

## Features
### Agent Management
- **Enhanced Agent Instantiation**: Added new attributes such as `skills` and `main` to agents, providing more detailed profiles.
- **New Agents Added**: Introduced four additional agents, each with multilingual support for names and descriptions.
- **Refactor to Agent Model**: Transitioned from `Assistant` to `Agent` model, simplifying handling of messages and referrals.

### Project Tools
- **Project Tools Management**: New controller (`ProjectToolsController`) added to manage tools, with views and JSON responses enhanced.
- **Project Stages Integration**: Introduced new project stages and improved API responses to reflect the current project state more accurately.
- **Localization Updates**: Added localization support for several aspects of project tools and agent instructions.

### Chat Functionality
- **Chat Enhancements**: Implemented chat functionality with `Chat::MessageAction`, enabling better interaction between users and AI agents.

### Documentation and Versioning
- **API Documentation**: Integrated `rswag` for improved API documentation generation and clarity.
- **Version Tracking for Agents**: Features introduced for tracking changes in agent versions with restore functionality.

## Fixes
- Numerous fixes to enhance stability:
    - Corrected time formatting for project updates.
    - Ensured proper handling of user presence in project naming.
    - Resolved issues in JSON responses for consistent messaging and project representation.
    - Improved validation handling in models for more robust error reporting.

## UX Updates
- Updated agent and project tool interfaces for a cleaner and more user-friendly experience.
- Enhanced agent details in JSON responses, providing additional context and clarity for users.

## Breaking Changes
- Transition from `Assistant` to `Agent` model required updates in the API routes and documentation to align with the new structure.
- Changes to the default email handling in mailers to ensure a cohesive branding experience across communications.

## Miscellaneous
- Continuous improvements to CORS settings and API request handling to ensure compatibility with various front-end applications.
- Regular optimization and performance tuning for database interactions related to agent and project tools.

This changelog summarizes key changes and improvements in the `fazinova-ai-api` repository over the past week, reflecting a strong focus on enhancing user experience and feature integration.
