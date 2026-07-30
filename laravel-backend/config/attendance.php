<?php

return [
    'jam_masuk_mulai' => env('ATTENDANCE_JAM_MASUK_MULAI', '06:00'),
    'jam_masuk_selesai' => env('ATTENDANCE_JAM_MASUK_SELESAI', '08:00'),
    'jam_pulang' => env('ATTENDANCE_JAM_PULANG', '16:00'),
    'biaya_lembur' => (int) env('ATTENDANCE_BIAYA_LEMBUR', 30000),
];
