#!/usr/bin/env bash
#
# Adapted from
#
# Nerd Fonts Version: 3.0.2
# Script Version: 1.1.1

# Run this script in your local bash:
# curl https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/bin/scripts/test-fonts.sh | bash
# Is possible to change the number of columns passing a number as the first parameter (default=16):
# ./test-fonts.sh 8

# Given an array of decimal numbers print all unicode codepoint.
function print-decimal-unicode-range() {
  local originalSequence=("$@")
  local counter=0
  local underline='\033[4m'
  local reset_color='\033[0m'
  local allChars=""
  local allCodes=""
  local wrapAt=16
  [[ "$wrappingValue" =~ ^[0-9]+$ ]] && [ "$wrappingValue" -gt 2 ] && wrapAt="$wrappingValue"
  local originalSequenceLength=${#originalSequence[@]}
  local leftoverSpaces=$((wrapAt - (originalSequenceLength % wrapAt)))

  # add fillers to array to maintain table:
  if [ "$leftoverSpaces" -lt "$wrapAt" ]; then
    for ((c = 1; c <= leftoverSpaces; c++)); do
      originalSequence+=(0)
    done
  fi

  local sequenceLength=${#originalSequence[@]}

  for decimalCode in "${originalSequence[@]}"; do
    local hexCode
    hexCode=$(printf '%x' "${decimalCode}")
    local code="${hexCode}"
    local char="\\U${hexCode}"

    # fill in placeholder cells properly formatted:
    if [ "${char}" = "\\U0" ]; then
      char=" "
      code=""
    fi

    filler=""
    for ((c = ${#code}; c < 5; c++)); do
      filler=" ${filler}"
    done

    allCodes+="${currentColorCode}${filler}${underline}${code}${reset_color}${currentColorCode} ${reset_color}$bar"
    allChars+="${currentColorChar}  ${char}   ${reset_color}$bar"
    counter=$((counter + 1))
    count=$(( (count + 1) % wrapAt))

    if [[ $count -eq 0 ]]; then

      if [[ "${currentColorCode}" = "${alternateBgColorCode}" ]]; then
        currentColorCode="${bgColorCode}"
        currentColorChar="${bgColorChar}"
      else
        currentColorCode="${alternateBgColorCode}"
        currentColorChar="${alternateBgColorChar}"
      fi

      printf "%b%b%b" "$bar" "$allCodes" "$reset_color"
      printf "\\n"
      printf "%b%b%b" "$bar" "$allChars" "$reset_color"
      printf "\\n"

      allCodes=""
      allChars=""
    fi

  done

}

function print-unicode-ranges() {
  echo ''

  local arr=("$@")
  local len=$#
  local combinedRanges=()

  for ((j=0; j<len; j+=2)); do
    local start="${arr[$j]}"
    local end="${arr[(($j+1))]}"
    local startDecimal=$((16#$start))
    local endDecimal=$((16#$end))

    # shellcheck disable=SC2207 # We DO WANT the output to be split
    combinedRanges+=($(seq "$startDecimal" "$endDecimal"))

  done

  print-decimal-unicode-range "${combinedRanges[@]}"

}

function test-fonts() {
  echo "Greek and Coptic"
  print-unicode-ranges 0370 03ff
  echo "Extended Greek - diacritics"
  print-unicode-ranges 1f00 1fff
  echo; echo
}

wrappingValue="$1"

test-fonts
