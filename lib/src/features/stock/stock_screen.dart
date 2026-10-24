import 'package:flutter/material.dart';

import '../../data/plantation_api.dart';
import '../../models/plantation_models.dart';
import '../../state/plantation_state.dart';
import '../../state/role_permissions.dart';
import '../../theme/app_theme.dart';
import '../shared/field_select_form_field.dart';
import '../shared/widgets.dart';

class StockScreen extends StatelessWidget {
  const StockScreen({required this.state, super.key});

  final PlantationState state;

  @override
  Widget build(BuildContext context) {
    final canUse = RolePermissions.canUseStock(state.role);
    final canMove = state.stockItemsForSelectedField.isNotEmpty && canUse;
    return ContentWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeading(
            title: 'Stocks & achats',
            subtitle: 'Suivez les entrées et les sorties',
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                if (RolePermissions.canRecordHarvestSale(state.role))
                  FilledButton.icon(
                    onPressed: () => _showHarvestSaleForm(context),
                    icon: const Icon(Icons.point_of_sale_outlined, size: 18),
                    label: const Text('Signaler une vente'),
                  ),
                if (RolePermissions.canDispatchStock(state.role))
                  IconButton(
                    tooltip: 'Ajouter un article',
                    onPressed: () => _showNewItemForm(context),
                    icon: const Icon(Icons.playlist_add),
                  ),
                if (RolePermissions.canOrderStock(state.role))
                  FilledButton.icon(
                    onPressed: state.stockItemsForSelectedField.isEmpty
                        ? null
                        : () => _showOrderForm(context),
                    icon: const Icon(Icons.shopping_cart_outlined),
                    label: const Text('Demander du matériel'),
                  ),
                if (RolePermissions.canManageWorkers(state.role))
                  IconButton(
                    tooltip: 'Signaler un matériel manquant',
                    onPressed: () => _showMaterialAlertForm(context),
                    icon: const Icon(
                      Icons.notification_add_outlined,
                      color: AppColors.cocoa,
                    ),
                  ),
                if (canMove)
                  PopupMenuButton<StockMovementKind>(
                    tooltip: 'Mouvement de stock',
                    onSelected: (kind) => _showMovementForm(context, kind),
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: StockMovementKind.usage,
                        child: Text('Déclarer une utilisation'),
                      ),
                    ],
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.forest,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, color: Colors.white, size: 19),
                            SizedBox(width: 7),
                            Text(
                              'Mouvement',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (state.api == null) const DemoNotice(),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SummaryCard(
                label: 'Références',
                value: '${state.stockItemsForSelectedField.length} articles',
                icon: Icons.inventory_2_outlined,
                tint: AppColors.leaf,
              ),
              SummaryCard(
                label: 'Quantité totale',
                value: '${state.stockQuantity} unités',
                icon: Icons.stacked_bar_chart,
                tint: const Color(0xFF5472A2),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (state.salesForSelectedField.isNotEmpty) ...[
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(title: 'Ventes récentes'),
                  for (final sale in state.salesForSelectedField.take(5))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.point_of_sale_outlined,
                        color: AppColors.forest,
                      ),
                      title: Text(sale.product),
                      subtitle: Text(
                        '${sale.quantity.toStringAsFixed(2).replaceAll('.', ',')} · '
                        '${formatShortDate(sale.recordedAt)} · ${sale.recordedBy}',
                      ),
                      trailing: Text(
                        formatCfa(sale.totalPrice),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],
          if (state.stockOrdersForSelectedField.isNotEmpty) ...[
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(title: 'Commandes de matériel'),
                  for (final order in state.stockOrdersForSelectedField)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        '${order.itemName} · demandé '
                        '${order.orderedQuantity.toStringAsFixed(0)} ${order.unit}',
                      ),
                      subtitle: Text(
                        '${order.description} · ${switch (order.status) {
                          StockOrderStatus.ordered => 'En attente de préparation par l’assistant',
                          StockOrderStatus.sent => 'Envoyé le ${formatShortDate(order.sentAt ?? order.orderedAt)} : ${order.receivedQuantity.toStringAsFixed(0)} ${order.unit} · prix unitaire ${formatCfa(order.unitPriceAtDispatch ?? 0)} · total ${formatCfa(order.paidAmount ?? 0)} · à confirmer à la réception',
                          StockOrderStatus.received => 'Reçu le ${formatShortDate(order.sentAt ?? order.orderedAt)} : ${order.receivedQuantity.toStringAsFixed(0)} ${order.unit} · prix unitaire ${formatCfa(order.unitPriceAtDispatch ?? 0)} · total ${formatCfa(order.paidAmount ?? 0)}',
                        }}',
                      ),
                      trailing:
                          RolePermissions.canDispatchStock(state.role) &&
                              order.status == StockOrderStatus.ordered
                          ? TextButton(
                              onPressed: () =>
                                  _dispatchStockOrder(context, order),
                              child: const Text('Préparer l’envoi'),
                            )
                          : RolePermissions.canReceiveStock(state.role) &&
                                order.status == StockOrderStatus.sent
                          ? Checkbox(
                              value: false,
                              onChanged: (_) => runApiAction(context, () async {
                                if (!await state.confirmStockOrderReceived(
                                  order.id,
                                )) {
                                  throw const ApiException(
                                    'Cette livraison ne peut pas être confirmée.',
                                  );
                                }
                              }),
                            )
                          : RolePermissions.canReceiveStock(state.role) &&
                                order.status == StockOrderStatus.received
                          ? const Checkbox(value: true, onChanged: null)
                          : order.status == StockOrderStatus.received
                          ? const Icon(
                              Icons.check_circle,
                              color: AppColors.leaf,
                            )
                          : null,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],
          if (state.materialAlertsForSelectedField.isNotEmpty) ...[
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionTitle(
                    title: 'Signalements du terrain',
                    action: Text(
                      '${state.materialAlertsForSelectedField.where((alert) => !alert.resolved).length} à traiter',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  for (final alert in state.materialAlertsForSelectedField)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: alert.resolved,
                      onChanged:
                          RolePermissions.canDispatchStock(state.role) &&
                              alert.kind == MaterialAlertKind.missing &&
                              !alert.resolved
                          ? (_) => runApiAction(context, () async {
                              if (!await state.resolveMaterialAlert(alert.id)) {
                                throw const ApiException(
                                  'Ce signalement ne peut pas être validé.',
                                );
                              }
                            })
                          : null,
                      title: Text(
                        alert.kind == MaterialAlertKind.delivery
                            ? 'Commande reçue : ${_itemName(alert.itemId)}'
                            : 'Manque signalé : ${_itemName(alert.itemId)}',
                      ),
                      subtitle: Text(
                        '${alert.quantity.toStringAsFixed(0)} ${_itemUnit(alert.itemId)} · ${alert.description} · ${alert.recordedBy}',
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],
          SurfaceCard(
            padding: const EdgeInsets.fromLTRB(18, 7, 18, 7),
            child: Column(
              children: [
                for (final item in state.stockItemsForSelectedField)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 5),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.paleGreen,
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        color: AppColors.forest,
                        size: 19,
                      ),
                    ),
                    title: Text(item.name),
                    subtitle: Text(
                      '${item.fieldName ?? 'Stock disponible'}'
                      '${item.unitPrice == null ? ' · Prix unitaire non défini' : ' · ${formatCfa(item.unitPrice!)} / ${item.unit}'}',
                    ),
                    trailing: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      children: [
                        Text(
                          '${item.quantity.toStringAsFixed(0)} ${item.unit}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (RolePermissions.canDispatchStock(state.role))
                          IconButton(
                            tooltip: 'Modifier le prix unitaire',
                            onPressed: () => _showUnitPriceForm(context, item),
                            icon: const Icon(Icons.edit_outlined, size: 19),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle(title: 'Mouvements récents'),
                if (state.stockMovementsForSelectedField.isEmpty)
                  const EmptyState(
                    title: 'Aucun mouvement',
                    description:
                        'Les réceptions et utilisations apparaîtront ici.',
                  )
                else
                  for (final movement in state.stockMovementsForSelectedField)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        movement.kind == StockMovementKind.receipt
                            ? Icons.south_west
                            : Icons.north_east,
                        color: movement.kind == StockMovementKind.receipt
                            ? AppColors.leaf
                            : AppColors.cocoa,
                      ),
                      title: Text(movement.description),
                      subtitle: Text(
                        '${_itemName(movement.itemId)} · ${formatRelativeTime(movement.recordedAt)} · ${movement.recordedBy}'
                        '${movement.kind == StockMovementKind.receipt && movement.paidAmount != null ? ' · Payé ${formatCfa(movement.paidAmount!)}' : ''}',
                      ),
                      trailing: Text(
                        '${movement.kind == StockMovementKind.receipt ? '+' : '−'}${movement.quantity.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showHarvestSaleForm(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final productController = TextEditingController();
    final quantityController = TextEditingController();
    final priceController = TextEditingController();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Signaler une vente de récolte',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: productController,
                decoration: const InputDecoration(
                  labelText: 'Produit récolté vendu',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Le nom du produit est obligatoire'
                    : null,
              ),
              const SizedBox(height: 11),
              TextFormField(
                controller: quantityController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Quantité vendue'),
                validator: _positiveValueValidator,
              ),
              const SizedBox(height: 11),
              TextFormField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Prix total reçu (F CFA)',
                ),
                validator: (value) {
                  final amount = int.tryParse((value ?? '').trim());
                  return amount == null || amount <= 0
                      ? 'Entrez un prix total supérieur à zéro'
                      : null;
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    var saleRecorded = false;
                    final completed = await runApiAction(context, () async {
                      saleRecorded = await state.addHarvestSale(
                        product: productController.text,
                        quantity: double.parse(
                          quantityController.text.trim().replaceAll(',', '.'),
                        ),
                        totalPrice: int.parse(priceController.text.trim()),
                      );
                      if (!saleRecorded) {
                        throw const ApiException(
                          'La vente n’a pas pu être enregistrée.',
                        );
                      }
                    });
                    if (!completed || !context.mounted) return;
                    Navigator.pop(context, true);
                  },
                  child: const Text('Enregistrer la vente'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vente ajoutée au rapport quotidien')),
      );
    }
  }

  Future<void> _showOrderForm(BuildContext context) async {
    if (state.stockItemsForSelectedField.isEmpty) return;
    final formKey = GlobalKey<FormState>();
    final quantityController = TextEditingController();
    final descriptionController = TextEditingController();
    var itemId = state.stockItemsForSelectedField.first.id;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Demander du matériel',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: itemId,
                  decoration: const InputDecoration(labelText: 'Article'),
                  items: [
                    for (final item in state.stockItemsForSelectedField)
                      DropdownMenuItem(
                        value: item.id,
                        child: Text('${item.name} (${item.unit})'),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) setModalState(() => itemId = value);
                  },
                ),
                const SizedBox(height: 11),
                TextFormField(
                  controller: quantityController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Quantité demandée',
                  ),
                  validator: _positiveValueValidator,
                ),
                const SizedBox(height: 11),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Détail / raison de la demande',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Le détail est obligatoire'
                      : null,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      var orderCreated = false;
                      final saved = await runApiAction(context, () async {
                        orderCreated = await state.createStockOrder(
                          itemId: itemId,
                          quantity: double.parse(
                            quantityController.text.trim().replaceAll(',', '.'),
                          ),
                          description: descriptionController.text,
                        );
                      });
                      if (!saved || !orderCreated || !context.mounted) return;
                      Navigator.pop(context, true);
                    },
                    child: const Text('Envoyer la demande à l’assistant'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demande envoyée à l’assistant')),
      );
    }
  }

  Future<void> _dispatchStockOrder(
    BuildContext context,
    StockOrder order,
  ) async {
    final formKey = GlobalKey<FormState>();
    final quantityController = TextEditingController(
      text: order.orderedQuantity.toString(),
    );
    final item = state.stockItems
        .where((stockItem) => stockItem.id == order.itemId)
        .firstOrNull;
    final unitPrice = item?.unitPrice;
    if (unitPrice == null || unitPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Définissez le prix unitaire avant de préparer l’envoi.',
          ),
        ),
      );
      return;
    }
    final received = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Préparer l’envoi : ${order.itemName}'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Quantité demandée : '
                  '${order.orderedQuantity.toStringAsFixed(0)} ${order.unit}',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: quantityController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Quantité à envoyer (${order.unit})',
                    helperText:
                        'Quantité demandée : ${order.orderedQuantity} ${order.unit}',
                  ),
                  validator: _positiveValueValidator,
                  onChanged: (_) => setDialogState(() {}),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Prix unitaire : ${formatCfa(unitPrice)} · '
                    'Total calculé : ${formatCfa(((double.tryParse(quantityController.text.replaceAll(',', '.')) ?? 0) * unitPrice).round())}',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                var orderSent = false;
                final saved = await runApiAction(context, () async {
                  orderSent = await state.dispatchStockOrder(
                    orderId: order.id,
                    sentQuantity: double.parse(
                      quantityController.text.trim().replaceAll(',', '.'),
                    ),
                  );
                });
                if (saved && orderSent && dialogContext.mounted) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('Envoyer au responsable'),
            ),
          ],
        ),
      ),
    );
    if (received == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Envoi préparé pour le responsable')),
      );
    }
  }

  Future<void> _showUnitPriceForm(BuildContext context, StockItem item) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(
      text: item.unitPrice?.toString() ?? '',
    );
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Prix unitaire : ${item.name}'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Prix (F CFA)'),
            validator: (value) {
              final price = int.tryParse((value ?? '').trim());
              return price == null || price <= 0
                  ? 'Entrez un prix supérieur à zéro'
                  : null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final completed = await runApiAction(context, () async {
                await state.updateStockItemPrice(
                  item.id,
                  int.parse(controller.text.trim()),
                );
              });
              if (completed && dialogContext.mounted) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Prix unitaire mis à jour')));
    }
  }

  String _itemName(String id) =>
      state.stockItemsForSelectedField
          .where((item) => item.id == id)
          .firstOrNull
          ?.name ??
      'Article';

  String _itemUnit(String id) =>
      state.stockItemsForSelectedField
          .where((item) => item.id == id)
          .firstOrNull
          ?.unit ??
      'unités';

  Future<void> _showMaterialAlertForm(BuildContext context) async {
    if (state.stockItemsForSelectedField.isEmpty) return;
    final formKey = GlobalKey<FormState>();
    final quantityController = TextEditingController();
    final descriptionController = TextEditingController();
    var itemId = state.stockItemsForSelectedField.first.id;
    var kind = MaterialAlertKind.missing;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Signaler au bureau',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<MaterialAlertKind>(
                  initialValue: kind,
                  decoration: const InputDecoration(labelText: 'Signalement'),
                  items: const [
                    DropdownMenuItem(
                      value: MaterialAlertKind.missing,
                      child: Text('Matériel manquant'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setModalState(() => kind = value);
                  },
                ),
                const SizedBox(height: 11),
                DropdownButtonFormField<String>(
                  initialValue: itemId,
                  decoration: const InputDecoration(labelText: 'Matériel'),
                  items: [
                    for (final item in state.stockItemsForSelectedField)
                      DropdownMenuItem(value: item.id, child: Text(item.name)),
                  ],
                  onChanged: (value) {
                    if (value != null) setModalState(() => itemId = value);
                  },
                ),
                const SizedBox(height: 11),
                TextFormField(
                  controller: quantityController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Quantité'),
                  validator: _positiveValueValidator,
                ),
                const SizedBox(height: 11),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Détail / remarque',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Le détail est obligatoire'
                      : null,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final reported = await runApiAction(context, () async {
                        await state.reportMaterialAlert(
                          itemId: itemId,
                          kind: kind,
                          quantity: double.parse(
                            quantityController.text.trim().replaceAll(',', '.'),
                          ),
                          description: descriptionController.text,
                        );
                      });
                      if (!reported || !context.mounted) return;
                      Navigator.pop(context, true);
                    },
                    child: const Text('Envoyer le signalement'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signalement transmis à l’assistant')),
      );
    }
  }

  Future<void> _showNewItemForm(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final unitController = TextEditingController();
    String? fieldId = state.selectedFieldId;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nouvel article',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nom de l’article',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Le nom est obligatoire'
                    : null,
              ),
              const SizedBox(height: 11),
              TextFormField(
                controller: unitController,
                decoration: const InputDecoration(
                  labelText: 'Unité (sac, litre, pièce…)',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'L’unité est obligatoire'
                    : null,
              ),
              const SizedBox(height: 17),
              FieldSelectFormField(
                state: state,
                onSaved: (value) => fieldId = value,
              ),
              const SizedBox(height: 17),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    formKey.currentState!.save();
                    final added = await runApiAction(context, () async {
                      await state.addStockItem(
                        nameController.text,
                        unitController.text,
                        fieldId: fieldId,
                      );
                    });
                    if (!added || !context.mounted) return;
                    Navigator.pop(context, true);
                  },
                  child: const Text('Ajouter au stock'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Article ajouté au stock')));
    }
  }

  Future<void> _showMovementForm(
    BuildContext context,
    StockMovementKind kind,
  ) async {
    final formKey = GlobalKey<FormState>();
    final quantityController = TextEditingController();
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    var itemId = state.stockItemsForSelectedField.first.id;
    final isReceipt = kind == StockMovementKind.receipt;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isReceipt
                      ? 'Réceptionner un achat'
                      : 'Déclarer une utilisation',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: itemId,
                  decoration: const InputDecoration(labelText: 'Article'),
                  items: [
                    for (final item in state.stockItemsForSelectedField)
                      DropdownMenuItem(
                        value: item.id,
                        child: Text(
                          '${item.name} (${item.quantity.toStringAsFixed(0)} ${item.unit})',
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) setModalState(() => itemId = value);
                  },
                ),
                const SizedBox(height: 11),
                TextFormField(
                  controller: quantityController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Quantité'),
                  validator: _positiveValueValidator,
                ),
                const SizedBox(height: 11),
                TextFormField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: isReceipt
                        ? 'Fournisseur / note'
                        : 'Motif d’utilisation',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Ce champ est obligatoire'
                      : null,
                ),
                if (isReceipt) ...[
                  const SizedBox(height: 11),
                  TextFormField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Prix payé (F CFA)',
                    ),
                    validator: _positiveValueValidator,
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      var success = false;
                      final saved = await runApiAction(context, () async {
                        success = await state.addStockMovement(
                          itemId: itemId,
                          kind: kind,
                          quantity: double.parse(
                            quantityController.text.trim().replaceAll(',', '.'),
                          ),
                          description: descriptionController.text,
                          paidAmount: isReceipt
                              ? int.parse(amountController.text.trim())
                              : null,
                        );
                        if (!success) {
                          throw const ApiException(
                            'Quantité indisponible pour cette sortie de stock.',
                          );
                        }
                      });
                      if (!saved || !context.mounted) return;
                      Navigator.pop(context, true);
                    },
                    child: const Text('Enregistrer le mouvement'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mouvement de stock enregistré')),
      );
    }
  }
}

String? _positiveValueValidator(String? value) {
  final number = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
  return number == null || !number.isFinite || number <= 0
      ? 'Entrez une valeur supérieure à zéro'
      : null;
}
