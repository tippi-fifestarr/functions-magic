const fs = require("fs")
const { Location, ReturnType, CodeLanguage } = require("@chainlink/functions-toolkit")

// configures request: via settings in the fields below
const requestConfig = {

    // source code location (inline only)
    codeLocation: Location.Inline,
    
    // (optional) if secrets are expected in the sourceLocation of secrets (only Remote or DONHosted is supported)
    secretsLocation: Location.DONHosted,
    
    // source code to be executed
    source: fs.readFileSync("./backstory-request.js").toString(),

    // (optional) accessed within the source code with `secrets.varName` (ie: secrets.apiKey), must be a string.
    secrets: { 
        apiKey: process.env.OPENAI_KEY
    },

    // args (array[""]): source code accesses via `args[index]`.
    args: [
        "Wizard", // character class
        "Elf", // character race
        "Eldon", // character name
        // "Chaotic Good", // character alignment
        // "Sage", // character background
        // ...[15, 14, 13, 12, 10, 8].map(String) // character abilities
    ],

    // code language (JavaScript only)
    codeLanguage: CodeLanguage.JavaScript,

    // shows: expected type of the returned value.
    expectedReturnType: ReturnType.string,
}

module.exports = requestConfig