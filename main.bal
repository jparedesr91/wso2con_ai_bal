import ballerinax/openai.chat;
import ballerina/http;
import ballerina/log;

configurable string token = ?;

listener http:Listener httpDefaultListener = http:getDefaultListener();

service / on httpDefaultListener {
    
    resource function get convert(string 'from = "ES", string to = "EN", string sentence = "Buenos Dias") returns json|error {

        final chat:Client openAIChat = check new ({auth: {token}});

        do {
            string|error translation = translate('from, to, sentence, openAIChat);

            if translation is error {
                log:printError("Error during translation: " + translation.toString());
                return error("Error during translation: " + translation.toString());
            }
            
            return {value: translation};

        } on fail error err {
            log:printError("Error during translation: " + err.message());
        }
    }
}

function translate(string sourceLanguage, string targetLanguage, string sentence, chat:Client openAIChat) returns string|error {
    chat:CreateChatCompletionRequest request = {
        model: "gpt-4o-mini",
        messages: [
            {role: "system", content: string `Translate the user sentence from ${sourceLanguage} to ${targetLanguage}` },
            {role: "user", content: sentence}
        ]
    };

    chat:CreateChatCompletionResponse response = check openAIChat->/chat/completions.post(request);

    string? command = response.choices[0].message.content;
    if command is () {
        return error("Failed to generate a valid command.");
    }
    return command;
}