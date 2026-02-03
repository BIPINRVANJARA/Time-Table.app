# Time Sorting Fix - Manual Instructions

## The Problem
Your subjects are showing in the wrong order because they were entered with **AM times instead of PM times**.

Looking at your screenshot:
- 12:30 AM - 1:30 AM  ← This should probably be **12:30 PM - 1:30 PM**
- 2:00 AM - 3:00 AM   ← This should probably be **2:00 PM - 3:00 PM**  
- 3:00 AM - 5:10 AM   ← This should probably be **3:00 PM - 5:10 PM**
- 10:30 AM - 11:30 AM ← This is correct
- 11:30 AM - 12:30 PM ← This is correct

## The Fix (Do This Now)

### Option 1: Edit Each Subject (Quick Fix)
1. Open the app
2. Tap on each subject that shows AM but should be PM
3. Change the time from AM to PM
4. Save

The sorting will work correctly once the times are correct.

### Option 2: Delete and Re-add (Clean Slate)
1. Delete all subjects with wrong AM/PM
2. Add them again with correct PM times
3. The sorting will work automatically

## Why This Happened
When you created the subjects, you selected AM instead of PM in the time picker.

## The Sorting IS Working!
The app is sorting correctly:
- 12:30 AM (30 minutes after midnight)
- 2:00 AM (120 minutes after midnight)
- 3:00 AM (180 minutes after midnight)
- 10:30 AM (630 minutes after midnight)
- 11:30 AM (690 minutes after midnight)

This IS chronological order from midnight onwards!

## After You Fix the Times
Once you change AM to PM, the order will be:
- 10:30 AM
- 11:30 AM
- 12:30 PM
- 2:00 PM
- 3:00 PM

Perfect chronological order!

## To Get the Updated App (With Timezone Fix for Notifications)
Your Flutter has build issues. Try:
```bash
flutter doctor
# Restart your computer
flutter run
```

The code fixes are already in the files, they just need to be compiled into the app.
