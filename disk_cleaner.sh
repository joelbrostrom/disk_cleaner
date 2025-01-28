#!/bin/bash

# Function to calculate and print the size of a directory
calculate_size() {
    local dir=$1
    du -sh "$dir" 2>/dev/null | awk '{print $1}'
}

# Function to convert human-readable size to bytes
convert_to_bytes() {
    local size=$1
    echo $size | awk '/K/{print $1*1024}/M/{print $1*1024*1024}/G/{print $1*1024*1024*1024}/T/{print $1*1024*1024*1024*1024}'
}

# Function to convert bytes to human-readable size
convert_to_human_readable() {
    local bytes=$1
    if [ "$bytes" -eq 0 ]; then
        echo "0 B"
    else
        echo $bytes | awk -v bytes="$bytes" '{
            split("B KB MB GB TB", units);
            for (i=5; i>=1; i--) {
                if (bytes >= 1024**(i-1)) {
                    printf "%.2f %s\n", bytes / 1024**(i-1), units[i];
                    break;
                }
            }
        }'
    fi
}

# Prompt the user for deletion preference
echo "Delete all unused data?"
echo "y: Delete all unused data"
echo "n: Choose which data to remove"
read delete_all

# Function to prompt the user before each deletion if they chose not to delete all
prompt_user() {
    local message=$1
    if [ "$delete_all" != "y" ]; then
        echo "$message (y/n)"
        read proceed
        if [ "$proceed" != "y" ]; then
            return 1
        fi
    fi
    return 0
}

total_deleted_size=0
data_deleted=false

## Remove iOS and Xcode Data
echo "Removing iOS and Xcode Data"

# Remove xcode device support cache
device_support_cache_dir=~/Library/Developer/Xcode/iOS\ DeviceSupport
initial_device_support_cache_size=$(calculate_size "$device_support_cache_dir")
if prompt_user "Do you want to remove xcode device support cache (Estimated size: $initial_device_support_cache_size)?"; then
    echo "Removing xcode device support cache (Estimated size: $initial_device_support_cache_size)..."
    if rm -rf "$device_support_cache_dir"/*/Symbols/System/Library/Caches/*; then
        current_device_support_cache_size=$(calculate_size "$device_support_cache_dir")
        initial_device_support_cache_size_bytes=$(convert_to_bytes "$initial_device_support_cache_size")
        current_device_support_cache_size_bytes=$(convert_to_bytes "$current_device_support_cache_size")
        removed_device_support_cache_size=$(($initial_device_support_cache_size_bytes - $current_device_support_cache_size_bytes))
        total_deleted_size=$(($total_deleted_size + $removed_device_support_cache_size))
        removed_device_support_cache_size_human=$(convert_to_human_readable "$removed_device_support_cache_size")
        echo "Removed xcode device support cache (Removed: $removed_device_support_cache_size_human)!"
        data_deleted=true
    else
        echo "Failed to remove xcode device support cache"
    fi
fi

# Remove xcode derived data
derived_data_dir=~/Library/Developer/Xcode/DerivedData
initial_derived_data_size=$(calculate_size "$derived_data_dir")
if prompt_user "Do you want to remove xcode derived data (Estimated size: $initial_derived_data_size)?"; then
    echo "Removing xcode derived data (Estimated size: $initial_derived_data_size)..."
    if rm -rf "$derived_data_dir"/*; then
        current_derived_data_size=$(calculate_size "$derived_data_dir")
        initial_derived_data_size_bytes=$(convert_to_bytes "$initial_derived_data_size")
        current_derived_data_size_bytes=$(convert_to_bytes "$current_derived_data_size")
        removed_derived_data_size=$(($initial_derived_data_size_bytes - $current_derived_data_size_bytes))
        total_deleted_size=$(($total_deleted_size + $removed_derived_data_size))
        removed_derived_data_size_human=$(convert_to_human_readable "$removed_derived_data_size")
        echo "Removed xcode derived data (Removed: $removed_derived_data_size_human)!"
        data_deleted=true
    else
        echo "Failed to remove xcode derived data"
    fi
fi

# Remove unused simulators
xcode_cache_dir=~/Library/Caches/com.apple.dt.Xcode
initial_xcode_cache_size=$(calculate_size "$xcode_cache_dir")
if prompt_user "Do you want to remove unused simulators (Estimated Size: $initial_xcode_cache_size)"; then
    echo "Removing unused simulators (Estimated Size: $initial_xcode_cache_size)"
    if xcrun simctl delete unavailable; then
        data_deleted=true
        current_xcode_cache_size=$(calculate_size "$xcode_cache_dir")
        initial_xcode_cache_size_bytes=$(convert_to_bytes "$initial_xcode_cache_size")
        current_xcode_cache_size_bytes=$(convert_to_bytes "$current_xcode_cache_size")
        removed_xcode_cache_size=$(($initial_xcode_cache_size_bytes - $current_xcode_cache_size_bytes))
        total_deleted_size=$(($total_deleted_size + $removed_xcode_cache_size))
        removed_xcode_cache_size_human=$(convert_to_human_readable "$removed_xcode_cache_size")
        echo "Removed unused simulators (Removed: $removed_xcode_cache_size_human)!"
    else
        echo "Failed to remove unused simulators"
    fi
fi

# Print total deleted size if any data was deleted
if [ "$data_deleted" = true ]; then
    total_deleted_size_human=$(convert_to_human_readable "$total_deleted_size")
    echo ""
    echo "Total deleted size: $total_deleted_size_human"
else
    echo "Nothing was deleted"
fi

## Free up more
echo ""
echo "Do you want to free up more space by manually deleting unused data? (y/n)"
read free_up_more

if [ "$free_up_more" = "y" ]; then
    delete_all="n"
    # Ask the user if they want to open the iOS device support folder to manually delete unused versions
    if prompt_user "Do you want to open the iOS device support folder to manually delete unused versions?"; then
        open "$device_support_cache_dir"
    fi

    # Ask the user if they want to open the Xcode Archives folder to manually delete unused versions
    xcode_archives_dir=~/Library/Developer/Xcode/Archives
    if prompt_user "Do you want to open the Xcode Archives folder to manually delete unused versions?"; then
        open "$xcode_archives_dir"
    fi

    # Ask the user if they want to open the Android SDK system images folder to manually delete unused versions
    android_sdk_system_images_dir=~/Library/Android/sdk/system-images
    if prompt_user "Do you want to open the Android SDK system images folder to manually delete unused versions?"; then
        open "$android_sdk_system_images_dir"
    fi

    # Ask the user if they want to open the Android AVD folder to manually delete unused versions
    android_avd_dir=~/.android/avd
    if prompt_user "Do you want to open the Android AVD folder to manually delete unused versions?"; then
        open "$android_avd_dir"
    fi
fi

echo ""
echo "Disk cleaning completed!"
