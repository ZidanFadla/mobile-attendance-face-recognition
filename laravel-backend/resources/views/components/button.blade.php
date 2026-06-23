@props([
    'type' => 'button',
    'variant' => 'primary',
])

@php
    $variantClasses = match ($variant) {
        'danger' => 'bg-red-600 text-white hover:bg-red-700 focus:ring-red-500',
        'outline' => 'border border-gray-300 bg-white text-gray-700 hover:bg-gray-50 focus:ring-gray-400',
        default => 'bg-emerald-600 text-white hover:bg-emerald-700 focus:ring-emerald-500',
    };
@endphp

<button
    type="{{ $type }}"
    {{ $attributes->class([
        'inline-flex items-center justify-center gap-2 rounded-lg px-4 py-2 text-sm font-semibold transition focus:outline-none focus:ring-2 focus:ring-offset-2',
        $variantClasses,
    ]) }}
>
    @isset($icon)
        {{ $icon }}
    @endisset

    {{ $slot }}
</button>
