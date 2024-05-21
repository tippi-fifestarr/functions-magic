// [1] ARGUMENT DECLARATION //

// gets: character class for the backstory.
const CHARACTER_CLASS = args[0] // --------------> |   Wizard

// gets: character race for the backstory.
const CHARACTER_RACE = args[1] // --------------> |   Elf

// gets: character name.
const CHARACTER_NAME = args[2] // --------------> |   Eldon

// gets: character alignment.
const CHARACTER_ALIGNMENT = args[3] // ----------> |   Chaotic Good

// gets: character background.
const CHARACTER_BACKGROUND = args[4] // ---------> |   Sage

// gets: character abilities.
const CHARACTER_ABILITIES = args.slice(5) // ----> |   [15, 14, 13, 12, 10, 8]

// [2] PROMPT ENGINEERING //

const prompt = 
`Generate a backstory for a ${CHARACTER_CLASS} named ${CHARACTER_NAME} who is a ${CHARACTER_RACE}. They are ${CHARACTER_ALIGNMENT} and their background is ${CHARACTER_BACKGROUND}.  The backstory should be engaging, coherent, and suitable for a fantasy RPG setting.`
// Their abilities are Strength: ${CHARACTER_ABILITIES[0]}, Dexterity: ${CHARACTER_ABILITIES[1]}, Constitution: ${CHARACTER_ABILITIES[2]}, Intelligence: ${CHARACTER_ABILITIES[3]}, Wisdom: ${CHARACTER_ABILITIES[4]}, Charisma: ${CHARACTER_ABILITIES[5]}.
console.log("Making OpenAI request with data: ", {
    url: `https://api.openai.com/v1/chat/completions`,
    method: "POST", 
    headers: { 
    "Content-Type": "application/json",
        "Authorization": `Bearer ${secrets.apiKey}`
    },
    data: {
        "model": "gpt-3.5-turbo",
        "messages": [
        {
            "role": "system",
            "content": "You are generating a character backstory."
        },
        {
            "role": "user",
            "content": prompt
        }
    ]},
    timeout: 10_000,
    maxTokens: 100,
    responseType: "json"
});

// [3] AI DATA REQUEST //

// requests: OpenAI API using Functions
const openAIRequest = await Functions.makeHttpRequest({
    url: `https://api.openai.com/v1/chat/completions`,
    method: "POST", 
    headers: { 
    "Content-Type": "application/json",
        "Authorization": `Bearer ${secrets.apiKey}`
    },
    data: {
        "model": "gpt-3.5-turbo",
        "messages": [
        {
            "role": "system",
            "content": "You are generating a character backstory."
        },
        {
            "role": "user",
            "content": prompt
        }
    ]},
    timeout: 10_000,
    maxTokens: 100,
    responseType: "json"
})


const response = await openAIRequest

console.log("Received OpenAI response: ", response.data);
// finds: the response and returns the result (as a string).
const backstory = response.data?.choices[0].message.content

console.log(`Generated backstory: %s`, backstory)

return Functions.encodeString(backstory || "Failed")