#!/bin/bash

echo "🧹 Cleaning up unused files..."

# Files safe to remove (enhanced versions that aren't used)
echo "Removing enhanced files that aren't used..."
rm -f main/EnhancedUploadView.swift
rm -f main/EnhancedUploadViewModel.swift
rm -f main/TickerControlView.swift
rm -f main/QuickMessageView.swift
rm -f main/RadioStatusView.swift
rm -f main/DreamHouseRadioEnhanced.swift

# Old/unused files
echo "Removing old/unused files..."
rm -f main/radiofeature.swift
rm -f main/RadioFlowListView.swift
rm -f main/ScheduleListView.swift
rm -f ShondonDHApp/RadioBlock.swift
rm -f ShondonDHApp/View/FilePickerView.swift
rm -f ShondonDHApp/View/Content+Item.swift

echo "✅ Cleanup complete!"
echo ""
echo "📁 Working files are in the 'mainapp' folder"
echo "📋 See mainapp/README.md for details"
echo ""
echo "🎵 Your app is now clean and organized!" 