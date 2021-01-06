package main

# latest tag
deny[msg] {
    input[i].Cmd == "from"
    val := split(input[i].Value[0], ":")
    count(val) == 1
    msg = sprintf("Line %d: Do not use latest tag with image: %s", [i, val])
}

# latest tag
deny[msg] {
    input[i].Cmd == "from"
    val := split(input[i].Value[0], ":")
    contains(lower(val[1]), "latest")
    msg = sprintf("Line %d: Do not use latest tag with image: %s", [i, input[i].Value])
}

# suspicious environemnt variables
suspicious_env_keys = [
    "passwd",
    "password",
    "secret",
    "key",
    "access",
    "api_key",
    "apikey",
    "token",
]

deny[msg] {    
    input[i].Cmd == "env"
    val := input[i].Value
    contains(lower(val[_]), suspicious_env_keys[_])
    msg = sprintf("Line %d: Suspicious ENV key found: %s", [i, val])
}

# ADD commands
deny[msg] {
   input[i].Cmd == "add"
   val := concat(" ", input[i].Value)
   msg = sprintf("Line %d: Use COPY instead of ADD: %s", [i, val])
}

# sudo usage
deny[msg] {
    input[i].Cmd == "run"
    val := concat(" ", input[i].Value)
    contains(lower(val), "sudo")
    msg = sprintf("Line %d: Avoid using 'sudo' command: %s", [i, val])
}

# any user
any_user {
    input[i].Cmd == "user"
}

deny[msg] {
    not any_user
    msg = "Do not run as root, use USER instead"
}

# do not root
forbidden_users = [
    "root",
    "toor",
    "0"
]

deny[msg] {
    input[i].Cmd == "user"
    val := input[i].Value
    contains(forbidden_users[_], lower(val[_]))
    msg = sprintf("Line %d: Do not run as root: %s", [i, val[_]])
}
