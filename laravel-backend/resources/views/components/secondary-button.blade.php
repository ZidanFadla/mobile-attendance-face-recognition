<button {{ $attributes->merge(['type' => 'button', 'class' => 'btn-secondary disabled:opacity-50']) }}>
    {{ $slot }}
</button>
