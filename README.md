# 4fpm
At least 4 frames per minute, or your money back guaranteed

## Requirements
This project is built for the Arduino Nano v3 but will likley work with other
Arduino boards, so long as they have a least 2 GPIO pins available

Build requirements:
 - CMake >= 3.19
 - llvm >= 12.0.0
 - avr-gcc >= 12.2.0
 - avr-libc >= 2.1.0
 - avr-binutils >= 2.40
 - avrdude >= 1.7
 - arduino-avr-core >= 1.8.3

## Building
### Build Flags
| Flag name | Default | Description |
| :--- | :--- | :--- |
| `4fpm_PEDANTIC` | `ON` | Enables pedantic compilation flags |
| `4fpm_DEBUG` | `OFF` | Enables debug code |
| `4fpm_LINK_ANDROID_CORE` | `OFF` | Use the Arduino core libraries instead of building as a free-standing project |
| `4fpm_LINK_AVR_LIBC` | `OFF` | Link against the Atmel avr-libc library |
| `4fpm_TESTS` | `OFF` | Build tests |

### Compiling and Uploading
If using neovim, the provided [`.nvimrc`](./.nvimrc) sets up convenience
mappings to:
 - `<C-j>` to build the project; sets the
   [`makeprg`](https://neovim.io/doc/user/options.html#'makeprg') option and
   runs the vimscript `make` command to build the project
 - `<C-u>` to upload the final rom

The results of the build and upload commands will be emitted into new named
buffers for ease-of-access.

Otherwise, you can manually build the project with the following commands:
```sh
mkdir build
cd build
env CC=clang CXX=clang++ cmake ..
cmake --build . -- rom
```

And to upload, you can run the following commands:
```sh
cd build
ARDUINO_SERIAL_PORT=/dev/SERIAL_PORT_HERE cmake --build . -- upload
```

### Testing
The test suite runs entirely on the host and does not require a board to run.

To build the test suite, set the `4fpm_TESTS` flag to `ON` when configuring the
project with the initial cmake command, ie.:
```sh
mkdir build
cd build
env CC=clang CXX=clang++ cmake .. -D4fpm_TESTS=ON
```

To build and run the tests, run the following command:
```sh
cd build
cmake --build . -- test
```

## License
This project is licensed under [The Unlicense](./LICENSE)
