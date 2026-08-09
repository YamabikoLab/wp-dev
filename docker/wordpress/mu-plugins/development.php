<?php

add_filter('wp_mail_from', static fn(): string => 'wordpress@example.test');

add_filter('wp_mail_from_name', static fn(): string => 'WordPress Development');

$editor_mode = getenv('EDITOR_MODE') ?: 'default';
$editor_mode_api_version = 'non-iframe' === $editor_mode ? 2 : 3;

add_action(
    'init',
    static function () use ($editor_mode_api_version): void {
        register_block_type(
            'wp-dev/editor-mode-marker',
            array(
                'api_version'     => $editor_mode_api_version,
                'title'           => 'wp-dev editor mode marker',
                'category'        => 'text',
                'supports'        => array(
                    'html'     => false,
                    'inserter' => false,
                    'reusable' => false,
                ),
                'render_callback' => static fn(): string => '',
            )
        );
    }
);

add_action(
    'enqueue_block_editor_assets',
    static function () use ($editor_mode, $editor_mode_api_version): void {
        $config = wp_json_encode(
            array(
                'apiVersion' => $editor_mode_api_version,
                'mode'       => $editor_mode,
            )
        );

        wp_register_script(
            'wp-dev-editor-mode',
            false,
            array('wp-blocks', 'wp-data', 'wp-dom-ready'),
            null
        );
        wp_enqueue_script('wp-dev-editor-mode');

        wp_add_inline_script(
            'wp-dev-editor-mode',
            <<<JS
(function (wp, config) {
    const blockName = 'wp-dev/editor-mode-marker';

    if (!wp.blocks.getBlockType(blockName)) {
        wp.blocks.registerBlockType(blockName, {
            apiVersion: config.apiVersion,
            title: 'wp-dev editor mode marker',
            category: 'text',
            supports: {
                html: false,
                inserter: false,
                reusable: false,
            },
            edit: function () { return null; },
            save: function () { return null; },
        });
    }

    if (config.mode !== 'non-iframe') {
        return;
    }

    wp.domReady(function () {
        const blockEditor = wp.data.select('core/block-editor');
        const blocks = blockEditor ? blockEditor.getBlocks() : [];

        if (blocks.some(function (block) { return block.name === blockName; })) {
            return;
        }

        wp.data.dispatch('core/block-editor').insertBlocks(
            wp.blocks.createBlock(blockName),
            0
        );
    });
})(window.wp, {$config});
JS,
            'after'
        );
    }
);
