@props([
    'type' => 'button',
    'variant' => 'primary',
])

@php
    $variantClasses = match ($variant) {
        'danger' => 'btn-danger',
        'outline' => 'btn-secondary',
        'secondary' => 'btn-secondary',
        default => 'btn-primary',
    };
@endphp

<button type="{{ $type }}" {{ $attributes->class([$variantClasses]) }}>
    @isset($icon)
        {{ $icon }}
    @endisset

    {{ $slot }}
</button>
