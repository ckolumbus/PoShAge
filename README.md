# README PoShAge

## About this module

A simple module that helps to use `age` with `powershell`.

## HowTo use age

Some examples on how to use age directly on the command line

!! Need to use `cmd /c` because powershell pipelining is broken,
it messes up the output piped into the `age -p` command

Or `--armor` can be used to wrap the encrypted data into a PEM format

## generate and encrypt at once

```cmd
cmd /c "age-keygen | age -p > key.age"
```

## decrypt (with checking passwor on the go) and export pub key

```cmd
cmd /c "age --decrypt -o - key.age | age-keygen.exe -y -o key.pub"
```

## extract pub keys from identities file

```cmd
age --decrypt -o - identities | age-keygen.exe -y -o identities.pub
```

## encrypt identities file with password

```cmd
age --encrypt -p -o .\identities i.txt
```

