export ZDOTDIR="$HOME/.config/zsh"
export SSH_AUTH_SOCK=/run/user/1000/ssh-agent.socket

# Added by get-aspire-cli.sh
export PATH="$HOME/.aspire/bin:$PATH"
export PATH="/home/jesper/dev/sdks/flutter/bin:$PATH"

# Flutter
export FLUTTER_HOME="$HOME/dev/sdks/flutter"
export PATH="$FLUTTER_HOME/bin:$PATH"

export CHROME_EXECUTABLE=/usr/bin/google-chrome-stable

# Java from Android Studio
export JAVA_HOME=/opt/android-studio/jbr
export PATH="$JAVA_HOME/bin:$PATH"

# Android SDK
export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$HOME/Android/Sdk"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

source "$HOME/.config/azure-devops-mcp/env"
