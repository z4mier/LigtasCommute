<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('otps', function (Blueprint $table) {
            // change otp to fixed length
            $table->char('otp', 6)->change();                 // requires doctrine/dbal
            // add an index to expires_at
            $table->index('expires_at', 'otps_expires_at_index');
        });
    }

    public function down(): void
    {
        Schema::table('otps', function (Blueprint $table) {
            // revert type and drop the named index
            $table->string('otp')->change();
            $table->dropIndex('otps_expires_at_index');
        });
    }
};
