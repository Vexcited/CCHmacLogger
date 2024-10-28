# CCHmacLogger

> A cute tweak to log CCHmac functions in iOS apps.

## Supported functions

- `CCHmac`
- `CCHmacInit`
- `CCHmacUpdate`
- `CCHmacFinal`

Inputs, outputs and key are logged in the file to help you debug the HMAC functions.

## Usage

```bash
make package
mv .theos/obj/debug/CCHmacLogger.dylib .
```

Now you have `CCHmacLogger.dylib` in the current directory.
Inject the `dylib` using any tool you want, for me it'll be **Sideloadly**.

Open Sideloadly, open any `.ipa` file, go into Advanced Options and in the "Signing Mode" section, select "Export IPA".
Next, in the "Tweak injection" section, select "Inject dylibs/frameworks" and add a "dylib/deb/bundle" and select the `CCHmacLogger.dylib` file you just compiled.
Start the injection process and you're good to go.

## Where to find the logs?

The logs are stored in `/path/to/app/data/Documents/CCHmacLogger.log` directory.

## Contributing

Feel free to contribute to this project by opening an issue or a pull request.
I would love to hear suggestions to improve this tweak - since it's my first tweak, I'm sure there are a lot of things that can be improved.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
