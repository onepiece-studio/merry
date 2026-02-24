#!/bin/bash

echo "开始转换 Surge 规则到 Clash 格式..."
mkdir -p Clash

count=0
for file in *.list; do
    [ -f "$file" ] || continue
    name="${file%.list}"
    echo "  转换: $file -> Clash/${name}.yaml"
    {
        echo "payload:"
        grep -v '^#' "$file" | grep -v '^$' \
            | grep -v '^USER-AGENT,' \
            | grep -v '^URL-REGEX,' \
            | grep -v '^SUBNET,' \
            | sed 's/^IP-ASN,/ASN,/' \
            | sed 's/^DEST-PORT,/DST-PORT,/' \
            | sed 's/^/  - /'
    } > "Clash/${name}.yaml"
    count=$((count + 1))
done

echo "完成！共转换 ${count} 个规则文件。"
