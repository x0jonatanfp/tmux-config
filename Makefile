.PHONY: test check-clean release

test:
	tests/test.sh

# Versión: la calcula commit-and-tag-version a partir de los commits desde la
# última etiqueta (`!` major, feat minor, fix patch, el resto nada). Escribe
# VERSION y el CHANGELOG.md, commitea `chore(release)` y etiqueta; si no hay
# feat, fix ni `!` nuevos, no hace nada.
CATV := npx -y commit-and-tag-version@13.3.0

check-clean:
	@test -z "$$(git status --porcelain)" || { echo "ERROR: hay cambios sin commitear; commitea antes de la release"; exit 1; }

release: check-clean
	$(CATV)
	git push --follow-tags
