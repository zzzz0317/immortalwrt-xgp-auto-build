'use strict';
'require baseclass';
'require rpc';

var callVersionInfo = rpc.declare({
	object: 'luci.zzversion',
	method: 'get_info',
	expect: { '': {} }
});

return baseclass.extend({
	title: _('固件信息'),

	load: function() {
		return callVersionInfo();
	},

	render: function(data) {
		var info = data || {};
		var release_info = info.release || {};
		var build_info = info.build || {};

		var table = E('table', { 'class': 'table' });

		var addRow = function(label, valueNodes) {
			table.appendChild(E('tr', { 'class': 'tr' }, [
				E('td', { 'class': 'td left', 'width': '33%', 'style': 'vertical-align:top' }, [ E('strong', {}, _(label)) ]),
				E('td', { 'class': 'td left' }, valueNodes)
			]));
		};

		addRow('版本', [
			(release_info.ZZ_DISTRIB_NAME || 'ImmortalWrt for XGPv3') + ' ' + (release_info.ZZ_DISTRIB_VERSION || 'Development Version'),
			E('br'),
			release_info.DISTRIB_DESCRIPTION || ''
		]);

		addRow('构建信息', [
			'构建 ID: ' + (build_info.ZZ_BUILD_ID || 'N/A'), E('br'),
			'构建日期: ' + (build_info.ZZ_BUILD_DATE || 'N/A'), E('br'),
			'构建主机: ' + (build_info.ZZ_BUILD_HOST || 'N/A'), E('br'),
			'构建用户: ' + (build_info.ZZ_BUILD_USER || 'N/A')
		]);

		addRow('仓库哈希', [
			'构建程序仓库: ' + (build_info.ZZ_BUILD_REPO_HASH || 'N/A'), E('br'),
			'ImmortalWrt: ' + (build_info.ZZ_BUILD_IMM_HASH || 'N/A')
		]);

		return E('div', {}, [ table ]);
	}
});
