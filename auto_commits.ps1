# ============================================
#  HELADRY AUTO COMMIT SCRIPT
#  Commits 9-30 (Commits 1-8 already done)
# ============================================

Set-Location "E:\flutter\flutter_application_1"

$commits = @(
    @{
        Num     = 9
        Time    = "2026-03-08 16:30:00"
        Add     = @("lib/theme/app_theme.dart")
        Message = "feat: setup app theme with light and dark mode support"
    },
    @{
        Num     = 10
        Time    = "2026-03-08 16:55:00"
        Add     = @("lib/theme/theme_controller.dart")
        Message = "feat: add theme controller for dynamic theme switching"
    },
    @{
        Num     = 11
        Time    = "2026-03-08 17:15:00"
        Add     = @("lib/widgets/primary_button.dart")
        Message = "feat: create reusable PrimaryButton widget component"
    },
    @{
        Num     = 12
        Time    = "2026-03-08 17:35:00"
        Add     = @("lib/widgets/secondary_button.dart")
        Message = "feat: create reusable SecondaryButton widget component"
    },
    @{
        Num     = 13
        Time    = "2026-03-08 17:55:00"
        Add     = @("lib/widgets/app_card.dart", "lib/widgets/app_text_field.dart")
        Message = "feat: create AppCard and AppTextField widget components"
    },
    @{
        Num     = 14
        Time    = "2026-03-08 18:15:00"
        Add     = @("lib/widgets/empty_state.dart", "lib/widgets/mode_toggle_button.dart", "lib/widgets/stepper_header.dart")
        Message = "feat: create EmptyState, ModeToggle, and StepperHeader widgets"
    },
    @{
        Num     = 15
        Time    = "2026-03-08 18:40:00"
        Add     = @("lib/services/session_store.dart")
        Message = "feat: implement session storage service"
    },
    @{
        Num     = 16
        Time    = "2026-03-08 19:00:00"
        Add     = @("lib/services/mock_device_service.dart", "lib/services/mock_wifi_service.dart")
        Message = "feat: add mock device and WiFi services for offline mode"
    },
    @{
        Num     = 17
        Time    = "2026-03-08 19:25:00"
        Add     = @("lib/app/mock_data.dart")
        Message = "feat: add mock data models and sample datasets"
    },
    @{
        Num     = 18
        Time    = "2026-03-08 19:50:00"
        Add     = @("lib/features/auth/pages/splash_page.dart")
        Message = "feat: implement splash screen with animated logo"
    },
    @{
        Num     = 19
        Time    = "2026-03-08 20:15:00"
        Add     = @("lib/features/auth/pages/login_page.dart")
        Message = "feat: implement login page with email and password auth"
    },
    @{
        Num     = 20
        Time    = "2026-03-08 20:40:00"
        Add     = @("lib/features/auth/pages/create_account_page.dart")
        Message = "feat: implement account creation page with form validation"
    },
    @{
        Num     = 21
        Time    = "2026-03-08 21:05:00"
        Add     = @("lib/features/connection/pages/connection_mode_page.dart")
        Message = "feat: implement connection mode selection page"
    },
    @{
        Num     = 22
        Time    = "2026-03-08 21:30:00"
        Add     = @("lib/features/pair/pages/pair_device_page.dart", "lib/features/pair/pages/pair_success_page.dart")
        Message = "feat: implement device pairing flow with BLE support"
    },
    @{
        Num     = 23
        Time    = "2026-03-08 22:00:00"
        Add     = @("lib/features/wifi/pages/wifi_setup_ble_step1_page.dart", "lib/features/wifi/pages/wifi_setup_ble_step2_page.dart", "lib/features/wifi/pages/wifi_setup_ble_step3_page.dart")
        Message = "feat: implement WiFi setup wizard (3-step BLE config)"
    },
    @{
        Num     = 24
        Time    = "2026-03-08 22:30:00"
        Add     = @("lib/features/dashboard/pages/dashboard_page.dart")
        Message = "feat: implement dashboard with live device monitoring UI"
    },
    @{
        Num     = 25
        Time    = "2026-03-08 23:00:00"
        Add     = @("lib/features/controls/pages/manual_controls_page.dart", "lib/features/guide/pages/crop_guide_page.dart")
        Message = "feat: implement manual controls and crop guide pages"
    },
    @{
        Num     = 26
        Time    = "2026-03-08 23:30:00"
        Add     = @("lib/features/batch/pages/start_new_batch_page.dart", "lib/features/records/pages/my_records_page.dart", "lib/features/settings/pages/settings_page.dart", "lib/features/settings/pages/edit_profile_page.dart")
        Message = "feat: implement batch tracking, records, and settings pages"
    },
    @{
        Num     = 27
        Time    = "2026-03-08 23:55:00"
        Add     = @("lib/app/routes.dart", "lib/app/app.dart")
        Message = "feat: configure app routes and root app widget"
    },
    @{
        Num     = 28
        Time    = "2026-03-09 00:05:00"
        Add     = @("lib/main.dart", "test/widget_test.dart")
        Message = "feat: add main entry point and widget test scaffold"
    },
    @{
        Num     = 29
        Time    = "2026-03-09 00:15:00"
        Add     = @("SDGP-HelaDry-CS154/platformio.ini", "SDGP-HelaDry-CS154/src/main.cpp", "SDGP-HelaDry-CS154/.gitignore")
        Message = "chore: add embedded IoT firmware project (SDGP-HelaDry-CS154)"
    },
    @{
        Num     = 30
        Time    = "2026-03-09 00:25:00"
        Add     = @("SDGP-HelaDry-CS154/include/README", "SDGP-HelaDry-CS154/lib/README", "SDGP-HelaDry-CS154/test/README")
        Message = "docs: add firmware project readme files"
    }
)

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  HELADRY AUTO COMMIT - STARTED" -ForegroundColor Cyan
Write-Host "  Commits remaining: $($commits.Count)" -ForegroundColor Cyan
Write-Host "  Keep this window open!" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

foreach ($commit in $commits) {
    $targetTime = [DateTime]::Parse($commit.Time)
    $now = Get-Date

    if ($targetTime -gt $now) {
        $waitMinutes = [math]::Round(($targetTime - $now).TotalMinutes, 1)
        Write-Host "[WAITING] Commit #$($commit.Num) scheduled at $($targetTime.ToString('hh:mm tt')). Waiting $waitMinutes min..." -ForegroundColor Yellow

        while ((Get-Date) -lt $targetTime) {
            Start-Sleep -Seconds 10
        }
    }
    else {
        Write-Host "[TIME PASSED] Commit #$($commit.Num) was for $($targetTime.ToString('hh:mm tt')). Running now..." -ForegroundColor DarkYellow
    }

    # Stage files
    foreach ($file in $commit.Add) {
        git add $file 2>&1 | Out-Null
    }

    # Commit
    $result = git commit -m $commit.Message 2>&1

    Write-Host "[COMMIT #$($commit.Num)] $(Get-Date -Format 'hh:mm:ss tt') - $($commit.Message)" -ForegroundColor Green
    Write-Host "  $result" -ForegroundColor Gray
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ALL COMMITS COMPLETED!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Now run manually:" -ForegroundColor Yellow
Write-Host "  git branch -M UI" -ForegroundColor White
Write-Host "  git push origin UI --force" -ForegroundColor White
Write-Host ""
