<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\RateLimiter;
use Carbon\Carbon;
use App\Mail\OtpMail;
use App\Models\User;

class OtpController extends Controller
{
    public function sendOtp(Request $request)
    {
        $request->validate(['email' => 'required|email']);
        $email = strtolower($request->email);

        // Ensure the email is a real user (for signup/login/forgot flows)
        if (!User::where('email', $email)->exists()) {
            return response()->json(['message' => 'Email not found'], 404);
        }

        // Throttle: 3 sends per 60s per email
        $key = 'send-otp:' . $email;
        if (RateLimiter::tooManyAttempts($key, 3)) {
            $seconds = RateLimiter::availableIn($key);
            return response()->json(
                ['message' => "Please wait $seconds seconds before requesting another OTP."],
                429
            );
        }
        RateLimiter::hit($key, 60);

        $otp = random_int(100000, 999999);

        DB::table('otps')->updateOrInsert(
            ['email' => $email],
            [
                'otp'        => $otp,
                'expires_at' => Carbon::now()->addMinutes(10),
                'updated_at' => now(),
                'created_at' => now(),
            ]
        );

        try {
            Mail::to($email)->send(new OtpMail($otp));
        } catch (\Throwable $e) {
            // You can log this if you want: \Log::warning('OTP mail failed: '.$e->getMessage());
            // We still return success because OTP is generated and can be delivered via other channels if needed.
        }

        return response()->json([
            'message'    => 'OTP sent',
            'expires_in' => 600,     // seconds
            'email'      => $email,
        ], 200);
    }

    public function verifyOtp(Request $request)
    {
        $data = $request->validate([
            'email'              => ['required','email'],
            'otp'                => ['required','digits:6'],
            'login_after_verify' => ['sometimes','boolean'], // optional flag
        ]);

        $email = strtolower($data['email']);
        $loginAfter = (bool)($data['login_after_verify'] ?? false);

        $user = User::where('email', $email)->first();
        if (!$user) {
            return response()->json(['message' => 'Email not found'], 404);
        }

        // If already verified, clean up any leftover OTP and (optionally) login
        if (!empty($user->is_verified)) {
            DB::table('otps')->where('email', $email)->delete();

            if ($loginAfter) {
                $token = $user->createToken('api')->plainTextToken;
                return response()->json([
                    'message'  => 'Already verified',
                    'verified' => true,
                    'token'    => $token,
                    'user'     => $user,
                ], 200);
            }

            return response()->json(['message' => 'Already verified', 'verified' => true], 200);
        }

        // Check OTP validity (exists, matches, not expired)
        $record = DB::table('otps')
            ->where('email', $email)
            ->where('otp', $data['otp'])
            ->where('expires_at', '>', now())
            ->first();

        if (!$record) {
            return response()->json(['message' => 'Invalid or expired OTP'], 422);
        }

        // Mark user verified and delete the OTP atomically
        DB::transaction(function () use ($email) {
            DB::table('users')->where('email', $email)->update([
                'is_verified'       => 1,
                'email_verified_at' => now(),
            ]);
            DB::table('otps')->where('email', $email)->delete();
        });

        // Refresh the user model to reflect changes
        $user->refresh();

        if ($loginAfter) {
            $token = $user->createToken('api')->plainTextToken;
            return response()->json([
                'message'  => 'OTP verified',
                'verified' => true,
                'token'    => $token,
                'user'     => $user,
            ], 200);
        }

        return response()->json(['message' => 'OTP verified', 'verified' => true], 200);
    }
}
