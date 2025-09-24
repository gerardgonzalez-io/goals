//
//  CalendarView.swift
//  Goals
//
//  Created by Adolfo Gerard Montilla Gonzalez on 24-09-25.
//

import SwiftUI

struct CalendarView: View {
    let topic: Topic

    // Calendario del sistema respetando la configuración regional del usuario
    private let calendar: Calendar =
    {
        var cal = Calendar.current
        cal.firstWeekday = Calendar.current.firstWeekday
        return cal
    }()

    // Fecha de referencia (hoy)
    private let today = Date()

    // Número de meses hacia atrás a mostrar (puedes aumentar si quieres "indefinido")
    private let monthsBack = 240 // ~20 años

    // Proveedor del estado de cumplimiento para un día concreto.
    // Reemplaza esta lógica con la fuente real de datos del `Topic` cuando esté disponible.
    private func isCompleted(on date: Date) -> Bool
    {
        // Ejemplo: marcar aleatoriamente días pasados como completados/no completados.
        // Para fechas futuras no mostrar indicador.
        if date > today { return false }
        // Determinístico por día para que no cambie al recargar: usar hash de componentes
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        let seed = (comps.year ?? 0) * 10_000 + (comps.month ?? 0) * 100 + (comps.day ?? 0)
        return seed % 3 == 0
    }

    var body: some View
    {
        ScrollView
        {
            LazyVStack(alignment: .leading, spacing: 24, pinnedViews: [.sectionHeaders])
            {
                ForEach(0..<(monthsBack + 1), id: \.self)
                { offset in
                    if let monthDate = calendar.date(byAdding: .month, value: -offset, to: firstOfCurrentMonth())
                    {
                        Section(header: MonthHeader(date: monthDate, calendar: calendar))
                        {
                            WeekdayRow(calendar: calendar)
                                .padding(.horizontal)

                            MonthGrid(
                                month: monthDate,
                                calendar: calendar,
                                today: today,
                                isCompleted: isCompleted(on:)
                            )
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .navigationTitle(topic.name)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
    }

    private func firstOfCurrentMonth() -> Date
    {
        let comps = calendar.dateComponents([.year, .month], from: today)
        return calendar.date(from: comps) ?? today
    }
}

// MARK: - Encabezado del mes
private struct MonthHeader: View
{
    let date: Date
    let calendar: Calendar

    var body: some View
    {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = .current
        formatter.dateFormat = "LLLL yyyy" // Nombre del mes + año

        return ZStack
        {
            // Material sutil para adherirse a las guías de diseño
            VisualEffectBlur(style: .systemThinMaterial)
                .ignoresSafeArea(edges: .horizontal)
            HStack
            {
                Text(formatter.string(from: date))
                    .font(.title2.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Fila de días de la semana
private struct WeekdayRow: View
{
    let calendar: Calendar

    var body: some View
    {
        let symbols = calendar.shortStandaloneWeekdaySymbols
        let ordered = Array(symbols[calendar.firstWeekday-1..<symbols.count]) + Array(symbols[0..<calendar.firstWeekday-1])
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7))
        {
            ForEach(ordered, id: \.self)
            { s in
                Text(s.uppercased())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Cuadrícula del mes
private struct MonthGrid: View
{
    let month: Date
    let calendar: Calendar
    let today: Date
    let isCompleted: (Date) -> Bool

    var body: some View
    {
        let days = makeDays()
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(minimum: 24), spacing: 0), count: 7), spacing: 12)
        {
            ForEach(days, id: \.self)
            { day in
                if let dayDate = day.date
                {
                    DayCell(date: dayDate,
                            isToday: calendar.isDate(dayDate, inSameDayAs: today),
                            inCurrentMonth: day.inCurrentMonth,
                            completed: isCompleted(dayDate))
                        .frame(height: 56)
                }
                else
                {
                    Color.clear.frame(height: 56)
                }
            }
        }
    }

    // Construye los "slots" del mes incluyendo espacios iniciales según el primer día de la semana
    private func makeDays() -> [DaySlot]
    {
        let range = calendar.range(of: .day, in: .month, for: month) ?? (1..<31)
        let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) ?? month
        let firstWeekdayIndex = calendar.component(.weekday, from: firstOfMonth)

        // Ajustar al primer día configurado en el calendario del usuario
        let leadingEmpty = (firstWeekdayIndex - calendar.firstWeekday + 7) % 7

        var result: [DaySlot] = []
        result.append(contentsOf: Array(repeating: DaySlot(date: nil, inCurrentMonth: false), count: leadingEmpty))

        for day in range
        {
            if let date = calendar.date(bySetting: .day, value: day, of: firstOfMonth)
            {
                result.append(DaySlot(date: date, inCurrentMonth: true))
            }
        }
        // Rellenar hasta múltiplo de 7 para cuadrícula completa
        while result.count % 7 != 0
        {
            result.append(DaySlot(date: nil, inCurrentMonth: false))
        }
        return result
    }

    struct DaySlot: Hashable
    {
        let date: Date?
        let inCurrentMonth: Bool
    }
}

// MARK: - Celda de día
private struct DayCell: View
{
    let date: Date
    let isToday: Bool
    let inCurrentMonth: Bool
    let completed: Bool

    var body: some View
    {
        VStack(spacing: 6)
        {
            Text(dayNumber)
                .font(.body.weight(isToday ? .semibold : .regular))
                .foregroundStyle(inCurrentMonth ? Color.primary : Color.secondary.opacity(0.3))
                .frame(maxWidth: .infinity)
                .overlay(alignment: .topTrailing)
                {
                    if isToday
                    {
                        Circle()
                            .strokeBorder(Color.accentColor.opacity(0.6), lineWidth: 1)
                            .frame(width: 22, height: 22)
                            .opacity(0) // marcador visual ligero si lo necesitas
                    }
                }

            // Indicador de cumplimiento
            Image(systemName: completed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .symbolRenderingMode(.palette)
                .foregroundStyle(completed ? Color.green : Color.red, Color.secondary.opacity(0.2))
                .font(.system(size: 14, weight: .semibold))
                .opacity(inCurrentMonth ? 1 : 0.3)
                .accessibilityLabel(completed ? "Completado" : "No completado")
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var dayNumber: String
    {
        let comps = Calendar.current.dateComponents([.day], from: date)
        return String(comps.day ?? 0)
    }

    private var accessibilityText: String
    {
        let df = DateFormatter()
        df.dateStyle = .full
        let base = df.string(from: date)
        return completed ? "\(base), objetivo completado" : "\(base), objetivo no completado"
    }
}

// MARK: - Utilidad de blur ligera para encabezado pegajoso
// Evita dependencias externas: pequeño wrapper que usa material del sistema
private struct VisualEffectBlur: UIViewRepresentable
{
    let style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView
    {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

#Preview
{
    CalendarView(topic: SampleData.shared.topic)
}
